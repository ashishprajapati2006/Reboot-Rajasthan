const db = require('../config/database');
const OpenAI = require('openai');
const { TwitterApi } = require('twitter-api-v2');
const sgMail = require('@sendgrid/mail');
const logger = require('../utils/logger');
const PDFDocument = require('pdfkit');
const fs = require('fs');
const path = require('path');

// Initialize OpenAI
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

// Initialize SendGrid
sgMail.setApiKey(process.env.SENDGRID_API_KEY || '');

class RTIService {
  /**
   * Generate RTI draft using GPT-4
   */
  async generateRTIDraft(complaintId, authorityName) {
    try {
      // Fetch complaint details
      const complaintResult = await db.query(
        `SELECT 
         c.id,
         c.complaint_number,
         c.filed_date,
         c.sla_deadline,
         i.issue_type,
         i.description,
         i.location_address,
         i.latitude,
         i.longitude,
         i.created_at,
         u.full_name,
         u.email,
         u.phone_number
         FROM rwa_complaints c
         JOIN issues i ON c.issue_id = i.id
         JOIN users u ON c.rwa_id = u.id
         WHERE c.id = $1`,
        [complaintId]
      );
      
      if (complaintResult.rows.length === 0) {
        throw new Error('Complaint not found');
      }
      
      const complaint = complaintResult.rows[0];
      
      // Generate RTI questions using GPT-4
      const prompt = `You are an expert legal assistant. Generate 7-10 specific RTI (Right to Information Act, 2005) questions for the following civic issue:

Issue Type: ${complaint.issue_type}
Description: ${complaint.description}
Location: ${complaint.location_address}
Complaint Filed Date: ${complaint.filed_date}
SLA Deadline: ${complaint.sla_deadline}

The RTI questions must:
1. Ask for specific documents, files, and correspondence
2. Request timeline and action-taken reports
3. Ask about budget allocation for the area
4. Request maintenance records and history
5. Ask about Standard Operating Procedures (SOP)
6. Inquire about responsible officers and departments
7. Ask for details of similar complaints in the area
8. Request information about contract details if outsourced

Return ONLY a JSON array of question objects with this format:
[
  {
    "question": "Full question text",
    "category": "DOCUMENTS|TIMELINE|BUDGET|MAINTENANCE|SOP|OFFICERS|COMPLAINTS|CONTRACTS"
  }
]`;
      
      const gptResponse = await openai.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.7,
        max_tokens: 1500
      });
      
      const questionsContent = gptResponse.choices[0].message.content;
      const questions = JSON.parse(questionsContent);
      
      // Generate RTI letter content
      const rtiLetter = this.formatRTILetter(complaint, questions, authorityName);
      
      // Generate RTI request number
      const rtiRequestNumber = `RTI/${new Date().getFullYear()}/${Date.now()}`;
      
      // Save RTI filing record
      const rtiResult = await db.query(
        `INSERT INTO rti_filings 
         (complaint_id, rti_request_number, questions, filing_status, rti_date)
         VALUES ($1, $2, $3, 'DRAFT', CURRENT_DATE)
         RETURNING id, rti_request_number`,
        [complaintId, rtiRequestNumber, JSON.stringify(questions)]
      );
      
      const rtiId = rtiResult.rows[0].id;
      
      // Generate PDF
      const pdfPath = await this.generateRTIPDF(
        rtiId,
        complaint,
        questions,
        authorityName,
        rtiRequestNumber
      );
      
      // Update with PDF path
      await db.query(
        `UPDATE rti_filings SET draft_document_url = $1 WHERE id = $2`,
        [pdfPath, rtiId]
      );
      
      logger.info(`RTI draft generated: ${rtiId} for complaint: ${complaintId}`);
      
      return {
        rtiId,
        rtiRequestNumber: rtiResult.rows[0].rti_request_number,
        questions,
        letterContent: rtiLetter,
        pdfPath
      };
    } catch (error) {
      logger.error('RTI draft generation failed:', error);
      throw error;
    }
  }

  /**
   * File RTI officially
   */
  async fileRTI(rtiId, emailTo) {
    const client = await db.connect();
    
    try {
      await client.query('BEGIN');
      
      // Get RTI details
      const rtiResult = await client.query(
        `SELECT 
         r.*,
         c.complaint_number,
         i.issue_type,
         i.location_address,
         u.full_name,
         u.email
         FROM rti_filings r
         JOIN rwa_complaints c ON r.complaint_id = c.id
         JOIN issues i ON c.issue_id = i.id
         JOIN users u ON c.rwa_id = u.id
         WHERE r.id = $1`,
        [rtiId]
      );
      
      if (rtiResult.rows.length === 0) {
        throw new Error('RTI filing not found');
      }
      
      const rti = rtiResult.rows[0];
      
      // Update RTI status
      await client.query(
        `UPDATE rti_filings 
         SET filing_status = 'FILED', 
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [rtiId]
      );
      
      // Log escalation
      await client.query(
        `INSERT INTO escalation_history 
         (complaint_id, escalation_type, target_authority, escalation_timestamp)
         VALUES ($1, 'RTI_FILING', $2, CURRENT_TIMESTAMP)`,
        [rti.complaint_id, emailTo]
      );
      
      // Update complaint escalation level
      await client.query(
        `UPDATE rwa_complaints 
         SET escalation_level = 1, 
             complaint_status = 'ESCALATED',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [rti.complaint_id]
      );
      
      await client.query('COMMIT');
      
      // Send RTI email
      if (emailTo && process.env.SENDGRID_API_KEY) {
        await this.sendRTIEmail(rti, emailTo);
      }
      
      logger.info(`RTI filed: ${rtiId}`);
      
      return {
        success: true,
        rtiId,
        rtiRequestNumber: rti.rti_request_number,
        filedTo: emailTo
      };
    } catch (error) {
      await client.query('ROLLBACK');
      logger.error('RTI filing failed:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Escalate issue on social media (Twitter)
   */
  async escalateOnSocialMedia(complaintId, includePhoto = true) {
    try {
      // Fetch complaint details
      const complaintResult = await db.query(
        `SELECT 
         c.complaint_number,
         c.filed_date,
         i.issue_type,
         i.description,
         i.location_address,
         i.issue_photo_url,
         i.severity
         FROM rwa_complaints c
         JOIN issues i ON c.issue_id = i.id
         WHERE c.id = $1`,
        [complaintId]
      );
      
      if (complaintResult.rows.length === 0) {
        throw new Error('Complaint not found');
      }
      
      const complaint = complaintResult.rows[0];
      
      // Generate tweet text
      const issueName = complaint.issue_type.replace(/_/g, ' ');
      const daysSinceFiling = Math.floor(
        (new Date() - new Date(complaint.filed_date)) / (1000 * 60 * 60 * 24)
      );
      
      const tweet = `🚨 URGENT: Unresolved ${issueName} at ${complaint.location_address}

Severity: ${complaint.severity}
Complaint #${complaint.complaint_number}
Filed: ${daysSinceFiling} days ago

@MunicipalCorp @CollectorOfficeRJ @CMORajasthan
Please take immediate action!

#CivicResponsibility #SAAFSURKSHA #Rajasthan`;
      
      // Initialize Twitter client
      if (!process.env.TWITTER_API_KEY) {
        throw new Error('Twitter API credentials not configured');
      }
      
      const twitterClient = new TwitterApi({
        appKey: process.env.TWITTER_API_KEY,
        appSecret: process.env.TWITTER_API_SECRET,
        accessToken: process.env.TWITTER_ACCESS_TOKEN,
        accessSecret: process.env.TWITTER_ACCESS_SECRET
      });
      
      // Post tweet
      const tweetResult = await twitterClient.v2.tweet(tweet);
      const tweetUrl = `https://twitter.com/i/web/status/${tweetResult.data.id}`;
      
      // Log escalation
      await db.query(
        `INSERT INTO escalation_history 
         (complaint_id, escalation_type, escalation_timestamp, social_media_urls)
         VALUES ($1, 'SOCIAL_MEDIA', CURRENT_TIMESTAMP, $2)`,
        [complaintId, JSON.stringify([tweetUrl])]
      );
      
      // Update complaint
      await db.query(
        `UPDATE rwa_complaints 
         SET escalation_level = GREATEST(escalation_level, 2),
             complaint_status = 'ESCALATED',
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $1`,
        [complaintId]
      );
      
      logger.info(`Social media escalation posted: Tweet ${tweetResult.data.id}`);
      
      return {
        success: true,
        tweetId: tweetResult.data.id,
        tweetUrl,
        text: tweet
      };
    } catch (error) {
      logger.error('Social media escalation failed:', error);
      throw error;
    }
  }

  /**
   * Monitor SLA deadlines and auto-escalate
   */
  async monitorSLA(complaintId) {
    try {
      const result = await db.query(
        `SELECT 
         c.id,
         c.sla_deadline,
         c.complaint_status,
         c.escalation_level,
         c.filed_date,
         i.severity
         FROM rwa_complaints c
         JOIN issues i ON c.issue_id = i.id
         WHERE c.id = $1`,
        [complaintId]
      );
      
      if (result.rows.length === 0) {
        throw new Error('Complaint not found');
      }
      
      const complaint = result.rows[0];
      const today = new Date();
      const deadline = new Date(complaint.sla_deadline);
      const daysRemaining = Math.floor((deadline - today) / (1000 * 60 * 60 * 24));
      
      let action = null;
      
      // Auto-escalate if SLA is breached
      if (daysRemaining <= 0 && complaint.complaint_status !== 'RESOLVED') {
        action = await this.escalateComplaint(complaintId, complaint.escalation_level + 1);
      } else if (daysRemaining <= 3 && complaint.escalation_level === 0) {
        // Send reminder 3 days before deadline
        await this.sendSLAReminder(complaintId, daysRemaining);
        action = 'reminder_sent';
      }
      
      return {
        complaintId,
        slaDeadline: complaint.sla_deadline,
        daysRemaining,
        isBreached: daysRemaining <= 0,
        currentEscalationLevel: complaint.escalation_level,
        action
      };
    } catch (error) {
      logger.error('SLA monitoring failed:', error);
      throw error;
    }
  }

  /**
   * Progressive escalation based on level
   */
  async escalateComplaint(complaintId, escalationLevel) {
    try {
      logger.info(`Escalating complaint ${complaintId} to level ${escalationLevel}`);
      
      let action = {};
      
      switch (escalationLevel) {
        case 1:
          // Level 1: File RTI
          action = await this.generateRTIDraft(complaintId, 'Municipal Authority');
          await this.fileRTI(action.rtiId, 'municipaloffice@rajasthan.gov.in');
          break;
          
        case 2:
          // Level 2: Social Media Escalation
          action = await this.escalateOnSocialMedia(complaintId);
          break;
          
        case 3:
          // Level 3: Legal Notice
          action = await this.generateLegalNotice(complaintId);
          break;
          
        default:
          throw new Error(`Invalid escalation level: ${escalationLevel}`);
      }
      
      // Update complaint escalation level
      await db.query(
        `UPDATE rwa_complaints 
         SET escalation_level = $1,
             updated_at = CURRENT_TIMESTAMP
         WHERE id = $2`,
        [escalationLevel, complaintId]
      );
      
      return {
        escalationLevel,
        action,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Complaint escalation failed:', error);
      throw error;
    }
  }

  /**
   * Format RTI letter content
   */
  formatRTILetter(complaint, questions, authorityName) {
    const letterDate = new Date().toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
    
    return `
REQUEST FOR INFORMATION UNDER RTI ACT 2005
==========================================

Date: ${letterDate}

To,
The Public Information Officer (PIO)
${authorityName}

Subject: Request for information regarding ${complaint.issue_type.replace(/_/g, ' ')}

Sir/Madam,

Under the Right to Information Act, 2005, I request the following information regarding the civic issue reported at ${complaint.location_address} (Complaint Reference: ${complaint.complaint_number}, Filed on: ${new Date(complaint.filed_date).toLocaleDateString('en-IN')}):

INFORMATION REQUESTED:

${questions.map((q, i) => `${i + 1}. ${q.question} (Category: ${q.category})`).join('\n\n')}

As per the provisions of the RTI Act, 2005, I request that the above information be provided within 30 days from the receipt of this application. If any of the requested information is held by another Public Authority, I request that my application be transferred to the concerned authority under Section 6(3) of the Act.

If my request is rejected, either fully or partially, please state the reasons for rejection and the relevant provisions of the RTI Act under which the rejection is made.

Yours Faithfully,
${complaint.full_name}
Email: ${complaint.email}
Phone: ${complaint.phone_number}

Date: ${letterDate}
`;
  }

  /**
   * Generate PDF document for RTI
   */
  async generateRTIPDF(rtiId, complaint, questions, authorityName, rtiRequestNumber) {
    return new Promise((resolve, reject) => {
      try {
        const fileName = `rti_${rtiRequestNumber.replace(/\//g, '_')}.pdf`;
        const filePath = path.join(__dirname, '..', '..', 'documents', fileName);
        
        // Ensure directory exists
        const dir = path.dirname(filePath);
        if (!fs.existsSync(dir)) {
          fs.mkdirSync(dir, { recursive: true });
        }
        
        const doc = new PDFDocument({ margin: 50 });
        const stream = fs.createWriteStream(filePath);
        
        doc.pipe(stream);
        
        // Header
        doc.fontSize(16).text('REQUEST FOR INFORMATION', { align: 'center' });
        doc.fontSize(14).text('UNDER RTI ACT 2005', { align: 'center' });
        doc.moveDown(2);
        
        // Content
        doc.fontSize(12).text(this.formatRTILetter(complaint, questions, authorityName));
        
        doc.end();
        
        stream.on('finish', () => {
          logger.info(`RTI PDF generated: ${filePath}`);
          resolve(filePath);
        });
        
        stream.on('error', reject);
      } catch (error) {
        reject(error);
      }
    });
  }

  /**
   * Send RTI via email
   */
  async sendRTIEmail(rti, toEmail) {
    try {
      const msg = {
        to: toEmail,
        from: process.env.SENDGRID_FROM_EMAIL || 'noreply@saafsurksha.in',
        subject: `RTI Request - ${rti.rti_request_number}`,
        text: `Please find attached RTI request for complaint ${rti.complaint_number}.`,
        html: `<p>Dear Sir/Madam,</p>
               <p>Please find attached the RTI request (Reference: ${rti.rti_request_number}) regarding ${rti.issue_type} at ${rti.location_address}.</p>
               <p>This is filed under the Right to Information Act, 2005.</p>
               <p>Regards,<br>${rti.full_name}</p>`,
        attachments: [
          {
            content: fs.readFileSync(rti.draft_document_url).toString('base64'),
            filename: `RTI_${rti.rti_request_number}.pdf`,
            type: 'application/pdf',
            disposition: 'attachment'
          }
        ]
      };
      
      await sgMail.send(msg);
      logger.info(`RTI email sent to ${toEmail}`);
    } catch (error) {
      logger.error('RTI email sending failed:', error);
      throw error;
    }
  }

  /**
   * Send SLA reminder
   */
  async sendSLAReminder(complaintId, daysRemaining) {
    try {
      logger.info(`SLA reminder sent for complaint ${complaintId}: ${daysRemaining} days remaining`);
      // Implement email/SMS notification
    } catch (error) {
      logger.error('SLA reminder failed:', error);
    }
  }

  /**
   * Generate legal notice
   */
  async generateLegalNotice(complaintId) {
    try {
      logger.info(`Legal notice generation for complaint ${complaintId}`);
      
      // Log escalation
      await db.query(
        `INSERT INTO escalation_history 
         (complaint_id, escalation_type, escalation_timestamp)
         VALUES ($1, 'LEGAL_NOTICE', CURRENT_TIMESTAMP)`,
        [complaintId]
      );
      
      return {
        noticeGenerated: true,
        level: 'LEGAL_NOTICE'
      };
    } catch (error) {
      logger.error('Legal notice generation failed:', error);
      throw error;
    }
  }
}

module.exports = new RTIService();
