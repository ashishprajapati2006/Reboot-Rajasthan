# Dashboard Feature - Quick Reference

## Button Navigation

### Home Screen
- **"My Dashboard" Button** → Opens `/dashboard` route
- Replaces the old "View Map" position
- Part of 2x2 quick action grid

### Design System Demo
- **"View Dashboard" Button** → Opens real `/dashboard` (fixed from placeholder)

## Main Features

### 1. View Issues
- List of all user-reported issues
- Real-time data from API
- Shows up to 50 issues

### 2. Filter Issues
```
Status Options:
- All (show everything)
- Pending (reported, not assigned)
- Assigned (assigned to teams)
- Resolved (work completed)
```

### 3. Issue Details
- Issue ID
- Type (Pothole, Garbage, Street Light, etc.)
- Status with color badge
- Priority level
- Location/address
- Description
- Creation date
- Vote count

### 4. Provide Feedback
- **Helpful Button**: Upvote completed work
- **Feedback Button**: Write detailed comments
- **Share Button**: Share issue (UI ready)

### 5. Verify Completion
- Green checkmark badge for resolved issues
- Shows completion status
- Prompts for feedback/verification

## Code Structure

```
lib/screens/dashboard/
├── dashboard_screen.dart (Main dashboard widget)
    ├── DashboardScreen (Stateful widget)
    ├── _DashboardScreenState (State management)
    ├── _buildIssueCard() (Card rendering)
    ├── _buildFilterChip() (Status filters)
    ├── _buildEmptyState() (No issues state)
    └── _buildVoteButton() (Feedback buttons)
```

## Key Methods

### Loading Issues
```dart
Future<void> _loadIssues()
- Calls ApiService().getIssues()
- Updates _issues state
- Handles errors
```

### Voting
```dart
Future<void> _voteOnIssue(String issueId, bool upvote)
- Calls ApiService().voteOnIssue()
- Refreshes issue list
- Shows success message
```

### Filtering
```dart
List<Map<String, dynamic>> _getFilteredIssues()
- Returns issues matching selected filter
- Called when _selectedFilter changes
```

## Color Scheme

| Status | Color | Meaning |
|--------|-------|---------|
| Pending | Orange | Not assigned yet |
| Assigned | Blue | Assigned to team |
| Resolved | Green | Work completed |
| Closed | Gray | Issue closed |

## Error Messages

| Scenario | Message |
|----------|---------|
| Network error | "Failed to load issues: [error]" |
| Vote failed | "Failed to vote: [error]" |
| Feedback empty | Validation required |
| Success | "Thank you for your feedback!" |

## API Routes Used

```
GET /api/v1/issues
├─ status: (optional) pending/assigned/resolved/closed
├─ type: (optional) issue type
├─ page: default 1
└─ limit: default 20

POST /api/v1/issues/{id}/vote
├─ upvote: boolean
└─ returns: updated issue
```

## State Variables

```dart
String _selectedFilter = 'all';      // Current status filter
bool _isLoading = true;              // Loading indicator
List<Map> _issues = [];              // Fetched issues from API
```

## UI Components Used

- **Scaffold**: Main layout
- **AppBar**: Header with title
- **FilterChip**: Status filters
- **ExpansionTile**: Expandable issue cards
- **CircleAvatar**: Issue type icons
- **Chip**: Status badge
- **ElevatedButton**: Vote buttons
- **AlertDialog**: Feedback modal
- **RefreshIndicator**: Pull-to-refresh
- **Center/SizedBox**: Spacing & alignment

## Interaction Flow

```
Screen Load
  ↓
_loadIssues() → API call
  ↓
Issues displayed in list
  ↓
User filters by status → _getFilteredIssues()
  ↓
User expands issue → Shows full details
  ↓
User votes/provides feedback → _voteOnIssue()
  ↓
Auto-refresh & show success
```

## Performance Notes

- Limits to 50 issues per load
- Pull-to-refresh for updates
- Efficient list building
- Error boundaries prevent crashes
- 30-second API timeout

## Testing Quick Checks

1. ✅ Dashboard loads without crashes
2. ✅ Issues display from API
3. ✅ Filters work correctly
4. ✅ Expansion shows full details
5. ✅ Voting records successfully
6. ✅ Feedback dialog works
7. ✅ Pull-to-refresh updates list
8. ✅ Empty state shows correctly
9. ✅ Error messages appear
10. ✅ Back button works

---

**Last Updated**: December 14, 2025
**Status**: ✅ Production Ready
