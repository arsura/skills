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

**Input:** Require two-factor authentication on login.

| | Text |
|---|------|
| WHAT | Require two-factor authentication on login |
| BAD WHY | Users should verify their identity with 2FA |
| GOOD WHY | Shared-password accounts led to unauthorized access on three customer orgs last quarter |

---

**Input:** Rate limit login API.

| | Text |
|---|------|
| WHAT | Limit login attempts to 5 per minute per IP |
| BAD WHY | Implement rate limiting on the login endpoint |
| GOOD WHY | Brute-force attempts spiked last month and risk account takeover without throttling |

## Full story example

**Input:** Clinic patients need to reschedule appointments online instead of calling reception. Issue: CARE-218.

```markdown
**WHO:** Patient using the clinic booking portal
**WHAT:** Reschedule an upcoming appointment to a new date and time slot
**WHY:** Phone rescheduling ties up reception staff and patients often wait on hold during peak hours

------

## Acceptance Criteria

### Patient reschedules to an available slot
- **GIVEN:**
  - the patient has a confirmed appointment in the future
  - **AND:** alternative slots exist for the same service type
- **WHEN:** the patient selects a new slot and confirms
- **THEN:**
  - the original appointment is cancelled
  - **AND:** the new appointment appears as confirmed in the portal

------

### Patient cannot reschedule inside the cutoff window
- **GIVEN:**
  - the appointment starts in less than 24 hours
- **WHEN:** the patient opens the reschedule flow
- **THEN:**
  - the portal shows that online rescheduling is unavailable
  - **AND:** offers a link to contact reception

------

### Patient receives confirmation email
- **GIVEN:**
  - the patient successfully rescheduled an appointment
- **WHEN:** the update is saved
- **THEN:**
  - the patient receives an email with the new date, time, and location
```

**Open Questions** (chat only, not pushed to Jira):

- Can patients reschedule across different doctors for the same service type?
- Should reception get a notification when a patient reschedules online?

## Code-like text in AC

Wrap field names, types, enums, and URL schemes in backticks (chat) or ADF `code` mark (Jira).

```markdown
**WHO:** Catalog manager
**WHAT:** Bulk-import product records into the admin console via CSV upload
**WHY:** Manual one-by-one entry delays seasonal launches and causes mismatched pricing across regions

------

## Acceptance Criteria

### Reject invalid status values
- **GIVEN:** a row has a `status` value that is not one of `DRAFT`, `ACTIVE`, `ARCHIVED`
- **WHEN:** the system validates the file
- **THEN:** the system rejects that row and reports the row number and the invalid value

------

### Validate redirect URL domain
- **GIVEN:** a row has a `redirect_url` that does not start with `https://shop.example.com/`
- **WHEN:** the system validates the file
- **THEN:** the system rejects that row and reports the row number and the URL that failed the whitelist check

------

### CSV Field Spec
| Field | Example | Required |
| `sku` | `WIDGET-42` | Yes |
| `status` | `ACTIVE` | Yes |
| `redirect_url` | `https://shop.example.com/widgets/42` | Optional |

Allowed `ProductStatus` enum values: `DRAFT`, `ACTIVE`, `ARCHIVED`
```

Note the divider after WHY, between scenarios, and before the user-requested appendix. No divider after the last section.
