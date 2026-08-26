# Output Examples - Good vs Bad

Both examples answer the same PM question: *"Tell me all the logic after clicking 'Summarize unread messages'."* (Type A: Functional logic question, Jupiter Web / Fiji.)

---

## Bad: engineering walkthrough first

> **Main flow after click:**
>
> 1. `NewSmartSummaryButton` checks availability via `smart_summary.smartSummaryConfig.enabled`, `hasCopilotPermission()`, and service parameter 1218.
> 2. The click handler calls `setShouldHideDot(true)`, then fires `SUMMARY_UNREAD_MESSAGE_NOTIFICATION_KEY + windowID` through `notificationCenter`.
> 3. `Summary.View.tsx` listens and calls `openCopilot()`.
> 4. `Summary.ViewModel.ts#getUnreadPosts()` reads local SQLite via `PostService.getUnreadPostsByGroupId()`, falls back to `getRemotePostsByGroupId()`, caps at 300 posts.
> 5. `CopilotService.uploadContent()` POSTs to `/message/copilot/content/upload`, returns `contextId`.
>
> **PM impact:** This feature has frontend, Copilot upload, AI SDK, license, and analytics dependencies. Engineering should confirm all owners.

Why this is bad:

- It leads with code sequence instead of functional behavior.
- Code identifiers appear in the body.
- Control logic is buried inside implementation details.
- It adds generic PM impact/next-step language even though the user asked for feature logic.

---

## Good: Type A functional logic answer

> ### 1. Answer
>
> Clicking the button starts an AI summary flow for the current conversation's unread messages. The user sees Copilot open, the app gathers eligible unread messages, sends them for summarization, then shows progress, success, error, and feedback states. The entry point is controlled by AI-summary feature configuration plus licensing, and the summary content is capped by a hard-coded message limit.
>
> ### 2. Functional Logic
>
> | Step / Condition | Behavior |
> |---|---|
> | Entry point visible | The button appears only when the AI summary capability is enabled and the user/account is eligible. |
> | User clicks the button | The app opens the Copilot summary experience for the current conversation. |
> | Message collection | The app collects unread messages from the current conversation, preferring local data and using a server fallback when needed. |
> | Too many unread messages | The app summarizes only up to the current hard-coded cap, using the latest eligible messages. |
> | AI request succeeds | The user sees the generated summary with feedback controls. |
> | AI request fails or is rate-limited | The user sees an error or limit state rather than a partial summary. |
>
> ### 3. Functional Controls
>
> | Control | Current value / default | Type | Controls what |
> |---|---|---|---|
> | AI summary enablement | Enabled only where configured | Feature config | Whether the entry point can appear |
> | AI summary entitlement | Service/license controlled | Entitlement | Which users/accounts can use the feature |
> | Unread-message cap | 300 messages | Hard-coded frontend limit | Maximum messages sent for one summary |
> | Message source fallback | Local first, remote fallback | Runtime behavior | Whether summary can still work when local data is incomplete |
> | Rate-limit handling | User-facing limit/error state | Backend/AI service behavior | What happens when usage limits are hit |
>
> ### 4. Key Branches
>
> - Eligible vs ineligible user/account: eligible users can see and use the button; ineligible users should not see the entry point.
> - Local data available vs unavailable: local unread messages are preferred; remote data is used as a fallback.
> - Within cap vs over cap: within cap summarizes all eligible unread messages; over cap summarizes only the capped set.
> - AI success vs failure/rate limit: success shows a summary; failure shows an error/limit state.
>
> ### 5. Unknowns / Limits
>
> - Live rollout audience is not confirmed by codebase analysis; check the feature/config platform for current production targeting.
> - The reason for the 300-message cap is not proven by code alone; assume cost, latency, or quality until Engineering confirms.
>
> ### 6. Confidence & Sources
>
> - Product confidence: high - the user-visible flow and controls are traceable.
> - Technical confidence: high - based on Fiji/Jupiter codebase analysis, task ID `41c4ead0-...`.
>
> ### 7. Technical Appendix
>
> Put component names, file paths, function names, endpoint names, analytics event names, and precise error handling here. Keep the appendix scannable and do not paste raw API JSON.

Why this is good:

- It answers the feature logic question directly.
- It separates behavior from controls and branches.
- It avoids generic next steps because the PM did not ask what to do next.
- It preserves implementation evidence only in the appendix.
