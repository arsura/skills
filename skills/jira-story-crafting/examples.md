# Examples: WHY validation and AC

## WHY — bad vs good

**Input:** Add date range filter on the orders page.

| | Text |
|---|------|
| WHAT | Add a date range filter on the orders page |
| BAD WHY | So users can filter orders by date |
| GOOD WHY | Support agents spend several minutes scrolling unrelated orders when handling date-specific complaints |

The bad WHY restates WHAT. The good WHY names the pain and cost.

---

**Input:** Export report to CSV.

| | Text |
|---|------|
| WHAT | Allow users to export the monthly sales report as CSV |
| BAD WHY | Users need to export the report to CSV |
| GOOD WHY | Finance reconciles sales in Excel today and manually re-enters data, which is slow and error-prone |

---

**Input:** Rate limit login API.

| | Text |
|---|------|
| WHAT | Limit login attempts to 5 per minute per IP |
| BAD WHY | Implement rate limiting on the login endpoint |
| GOOD WHY | Brute-force attempts spiked last month and risk account takeover without throttling |

## Full story example

**Input:** Restaurant owners want to pause orders during rush hour without closing the store. Issue: FOOD-482.

```markdown
**WHO:** Restaurant owner on the merchant app
**WHAT:** Pause incoming orders temporarily while keeping the store listed as open
**WHY:** During unexpected rushes, owners cannot fulfill orders in time and receive cancellations that hurt their rating

**Acceptance Criteria**

Owner pauses orders from the dashboard
- **GIVEN:**
  - the store is open and accepting orders
- **WHEN:** the owner taps Pause orders and confirms
- **THEN:**
  - new customer orders are blocked
  - **AND:** the store still appears open on the consumer app

Owner resumes orders
- **GIVEN:**
  - orders are paused
- **WHEN:** the owner taps Resume orders
- **THEN:**
  - new orders are accepted again
  - **AND:** the pause state clears without a page reload

Pause expires automatically
- **GIVEN:**
  - the owner paused orders with a 30-minute duration
  - **AND:** 30 minutes have elapsed
- **WHEN:** the timer expires
- **THEN:**
  - orders resume automatically
  - **AND:** the owner receives a push notification
```

**Open Questions** (chat only, not pushed to Jira):

- Should pause support a fixed duration, manual resume only, or both?
- Should the consumer app show that the store is temporarily not accepting orders?
