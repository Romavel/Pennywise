# Pennywise — design tokens (from the screen mockups)

Screens are in `screens/*.dc.html` (HTML mockups, 390×844 phone frame). Treat them as visual reference for Flutter widgets, not code to port.

## Screens → Flutter routes
| File | Screen | Route |
|---|---|---|
| Splash.dc.html | Splash / Firebase init | /splash |
| Login.dc.html | Log in / Sign up (tabs) | /auth |
| Main.dc.html | Dashboard | /dashboard |
| Transactions.dc.html | Transaction list + filters | /transactions |
| TransactionForm.dc.html | Add / edit transaction | /transactions/new, /transactions/:id |
| Budgets.dc.html | Budget list | /budgets |
| BudgetDetail.dc.html | Budget details | /budgets/:id |
| Reports.dc.html | Reports | /reports |
| Settings.dc.html | Settings | /settings |
| Categories.dc.html | Categories | /settings/categories |
| DashboardDark / BudgetsDark | Dark theme reference | — |

Bottom NavigationBar (Dashboard, Transactions, Budgets, Reports, Settings) is always visible; content scrolls above it. FAB "+" (orange, 60×60, radius 20) opens the transaction form.

## Colors — light
- background `#F3F5F4`, surface `#FFFFFF`, text `#12201E`, muted text `#5B6663`
- primary `#0F4C45` (deep green), on-primary `#FFFFFF`, primary container `#DCEBE6`
- accent / FAB `#E07B39`
- divider `#EDF1EF`, track / border `#E3E9E7`, input border `#D3DCD9`
- income `#14613F`, expense `#B23F0E`
- budget bar: ok `#0F4C45`, ≥90% `#B7790F`, over `#C2410C`; warning bg `#FDE7DC` / fg `#9A3412`

## Colors — dark
- background `#0E1514`, surface `#18221F`, text `#E8EEEC`, muted `#9AA8A3`
- primary `#4CC3A0`, on-primary `#06201A`, hero card `#14463F`, nav pill `#1E3A34`, nav active `#7FD8BC`
- divider `#24302D`, track `#26332F`
- income `#6FD6A6`, expense `#F59A6E`; budget near `#F2B544`, over `#F2875A`

## Category colors (tile bg / icon)
Food `#FBE6D7`/`#9A4A16` · Transport `#DDEBF3`/`#245E80` · Housing `#DCE7EA`/`#173F4F` · Shopping `#FBF0D2`/`#7A5B0E` · Entertainment `#ECE4F3`/`#5B3F7A` · Health `#F7E0E0`/`#8E2F2F` · Education `#E2E8F6`/`#2E4A8A` · Other `#E8ECEA`/`#3F4A47` · Income categories `#DCEFE5`/`#14613F`
Chart colors: Housing `#173F4F`, Food `#E07B39`, Transport `#5C9EC4`, Shopping `#F2C14E`, Other `#B9C2BE`

## Typography (Google Fonts)
- Display / amounts: **Bricolage Grotesque** 700 (screen titles 28, balance 36, card amounts 22)
- Body / UI: **DM Sans** 400–700 (body 15, labels 13, captions 12, nav 11)
- Amounts use tabular figures.

## Shape & spacing
- Screen padding 20 horizontal, 52 top; section gap 14–18
- Radii: cards 20–24, list groups 16–18, inputs 14, icon tiles 11–12, chips/pills 999
- Touch targets ≥ 44; bottom nav height 76; primary button height 54, radius 16
- Segmented controls: track `#E3E9E7`, radius 14, selected segment white with soft shadow
