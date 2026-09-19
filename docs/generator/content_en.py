# -*- coding: utf-8 -*-
"""English edition aimed at restaurant owners and operators, not developers."""

TITLE = "PaynEat POS"
SUBTITLE = "Point-of-Sale built for restaurants"
TAGLINE = ("From the first order to the closed bill — one system running on the phones, "
           "tablets and computers your team already uses")

INTRO = {
    "why": [
        ("Orders stop getting lost",
         "The moment a server confirms an order it appears on the kitchen screen — "
         "no paper tickets, no shouting across a busy service."),
        ("Every bill adds up correctly",
         "Discounts, service charge and VAT are applied identically every time, and split "
         "payments need no calculator."),
        ("You see the numbers while the day is still running",
         "Sales, busiest hours and best sellers update as bills close, not at month end."),
    ],
    "stats": [
        ("5", "staff roles"),
        ("29", "screens"),
        ("3", "device sizes"),
        ("4", "payment methods"),
        ("0", "licence fees"),
        ("100%", "on-premise"),
    ],
    "roles": [
        ("Servers", "Phone or tablet", "Floor plan · take orders · mark served"),
        ("Kitchen", "Tablet or wall screen", "Live ticket queue, no printer needed"),
        ("Cashier", "Tablet or computer", "Take payment · discounts · receipts"),
        ("Manager / Owner", "Computer (web browser)", "Dashboard · menu · staff · reports"),
    ],
}

SECTIONS = [
    {
        "id": "waiter",
        "no": "01",
        "title": "Taking orders — front of house",
        "lead": "The screens servers touch hundreds of times a shift, built for one-handed use.",
        "device": "phone",
        "screens": [
            {
                "img": "phone-01-login.png",
                "name": "Sign in",
                "lead": "Every shift starts here, and each person only ever sees the tools for their job.",
                "points": [
                    "Five separate roles: admin, manager, server, cashier and kitchen. "
                    "A server simply never sees staff records or takings.",
                    "Accounts are created and disabled by the manager, so a departing employee "
                    "loses access the same day.",
                    "Demo accounts are included so you can try each role before committing to anything.",
                ],
                "tech": "Permissions are enforced by the server, not just hidden in the app. "
                        "Someone cannot reach a screen they are not entitled to.",
            },
            {
                "img": "phone-02-tables.png",
                "name": "Floor plan",
                "lead": "The state of your whole dining room at a glance.",
                "points": [
                    "Green means free, orange means occupied. New staff learn it in under a minute.",
                    "Each occupied table shows the running total and how long the guests have been "
                    "seated, so you can see which tables are close to paying.",
                    "Tables are grouped by the zones you actually use, so finding a table on screen "
                    "matches walking to it.",
                ],
                "tech": "The plan updates by itself. When a colleague opens or closes a bill on another "
                        "device, every screen in the restaurant reflects it within a second.",
            },
            {
                "img": "phone-03-order-taking.png",
                "name": "Choosing dishes",
                "lead": "Fewer taps per order means shorter queues at the table.",
                "points": [
                    "Search and category filters respond instantly, even on a weak Wi-Fi signal.",
                    "Dishes that have run out are greyed out and cannot be ordered by mistake — "
                    "the kitchen can switch them off themselves.",
                    "Recommended dishes carry a badge, which is a simple way to push higher-margin items.",
                ],
                "tech": "Ninety percent of orders are placed in two taps: pick the table, pick the dish.",
            },
            {
                "img": "phone-04-option-sheet.png",
                "name": "Options and special requests",
                "lead": "\"Extra spicy, add a fried egg, no coriander\" — captured exactly.",
                "points": [
                    "Required choices such as spice level cannot be skipped, so the kitchen never has "
                    "to chase a server for an answer.",
                    "Paid extras are added to the price automatically, so add-ons stop leaking revenue.",
                    "Free-text notes go straight to the kitchen ticket, highlighted so they are not missed.",
                ],
                "tech": "You define which options exist, whether they are compulsory and how much they "
                        "cost — no developer needed.",
            },
            {
                "img": "phone-05-cart.png",
                "name": "The order before it is sent",
                "lead": "Servers can answer \"how much is that?\" before the food is even cooked.",
                "points": [
                    "Identical items are combined automatically, so a table ordering four of the same "
                    "drink reads as one clean line.",
                    "Service charge and VAT are shown separately from the start — no surprises at the till.",
                    "An order can be sent to the kitchen immediately, or held while the table keeps deciding.",
                ],
                "tech": "The total shown is calculated with exactly the same rules the till uses, "
                        "so the figure quoted at the table is the figure on the bill.",
            },
            {
                "img": "phone-06-order-detail.png",
                "name": "An open bill",
                "lead": "Everything about one table in a single screen.",
                "points": [
                    "Each dish carries its own status, so a server knows what is still in the kitchen "
                    "and what is ready to carry out.",
                    "Once the kitchen has started cooking, a dish can no longer be quietly edited or "
                    "deleted — only a manager can void it. That protects both food cost and takings.",
                    "Adding a second round to the same bill is one tap, no new bill required.",
                ],
                "tech": "Every void is recorded against the manager who approved it.",
            },
            {
                "img": "phone-07-orders.png",
                "name": "All orders",
                "lead": "For following what is outstanding across the whole restaurant.",
                "points": [
                    "Filters follow the real working order: not yet sent, in the kitchen, all served, paid.",
                    "Useful during a rush to spot a table that has been waiting too long.",
                    "Closed bills from today stay available for checking a query with a guest.",
                ],
                "tech": "The list refreshes on its own as bills move through the service.",
            },
            {
                "img": "phone-11-profile.png",
                "name": "Account and connection",
                "lead": "Small screen, but it answers the question staff ask most: \"is it still connected?\"",
                "points": [
                    "A green dot confirms the device is live with the rest of the restaurant.",
                    "Shows which role is signed in, which prevents work being logged to the wrong person.",
                    "Signing out asks for confirmation, so it does not happen by accident mid-shift.",
                ],
                "tech": "If the connection drops, the indicator turns grey immediately rather than "
                        "letting staff believe orders are being sent.",
            },
        ],
    },
    {
        "id": "kitchen",
        "no": "02",
        "title": "The kitchen display",
        "lead": "Replaces the printer and the paper spike — readable from across the pass.",
        "device": "mixed",
        "screens": [
            {
                "img": "tablet-14-kitchen.png",
                "name": "Live ticket queue",
                "lead": "Three columns showing the whole kitchen's workload at once.",
                "points": [
                    "Tickets appear the instant a server confirms them. Nothing to print, nothing to lose.",
                    "Any dish waiting longer than fifteen minutes turns red with a flame icon, and a "
                    "counter at the top shows how many are running late. Problems surface before the "
                    "guest complains.",
                    "Guest requests are highlighted in yellow so they are never buried under the dish name.",
                    "One large button per ticket moves it forward. There is nothing else to learn.",
                ],
                "tech": "Waiting times update continuously without anyone touching the screen. "
                        "A quiet kitchen screen genuinely means there is no outstanding work.",
            },
            {
                "img": "phone-08-kitchen.png",
                "name": "Kitchen view on a phone",
                "lead": "The same queue on a smaller screen, arranged as tabs.",
                "points": [
                    "Works as a backup when the main kitchen tablet is occupied or being charged.",
                    "Useful for a prep station or a bar that only handles part of the menu.",
                    "The kitchen can mark a dish as sold out here, and it disappears from every "
                    "server's menu immediately.",
                ],
                "tech": "Adding another screen costs nothing — it is the same application, "
                        "signed in on another device.",
            },
        ],
    },
    {
        "id": "cashier",
        "no": "03",
        "title": "Payment and receipts",
        "lead": "The part of service that has to be right every time.",
        "device": "mixed",
        "screens": [
            {
                "img": "tablet-16-checkout.png",
                "name": "Taking payment",
                "lead": "The bill on the left, the payment on the right, finished in one screen.",
                "points": [
                    "Split payments are standard, not an afterthought: part on QR, the rest in cash, "
                    "with the outstanding balance tracked automatically.",
                    "Change is calculated as the cashier types, with shortcut buttons for the notes "
                    "guests actually hand over.",
                    "Overpaying a balance is simply not possible, and when the bill is settled the "
                    "table is released for the next guests without anyone remembering to do it.",
                ],
                "tech": "The outstanding balance is always recalculated from the payments actually "
                        "recorded, so a bill settled in three parts still balances to the satang.",
            },
            {
                "img": "phone-34-promptpay-qr.png",
                "name": "A real PromptPay QR code",
                "lead": "Choose \"PromptPay / QR\" and the guest gets a working code to scan, not just a label.",
                "points": [
                    "Generated to the national EMV QR standard, with the amount locked to the balance "
                    "actually due on that bill — including a partial amount on a split payment.",
                    "Works whether the restaurant's PromptPay ID is a phone number or a 13-digit "
                    "tax/citizen ID.",
                    "If no PromptPay ID has been set up yet, the system says so plainly instead of "
                    "handing the guest a code that will not work.",
                ],
                "tech": "The QR payload is generated by matching logic on the server and in the app, "
                        "with a shared test suite that proves both sides produce byte-identical output.",
            },
            {
                "img": "phone-09-checkout.png",
                "name": "Paying at the table",
                "lead": "The same process on a phone, for restaurants that settle bills at the table.",
                "points": [
                    "Nothing is removed on the smaller screen — discounts, split payments and change "
                    "all work identically.",
                    "Change due is shown in large green type, because it is the number read aloud "
                    "to the guest.",
                    "Payments already taken against the bill are listed, so a second cashier can "
                    "pick up where the first left off.",
                ],
                "tech": "Useful for terraces and outdoor seating where walking a guest to a till "
                        "is impractical.",
            },
            {
                "img": "phone-10-receipt.png",
                "name": "Receipt",
                "lead": "Laid out like a printed slip, and it prints to a real thermal printer "
                        "from the same button.",
                "points": [
                    "Shows every dish with its options, then discount, service charge and VAT "
                    "on separate lines — the breakdown a guest or an auditor expects.",
                    "Lists each payment method used and the total change given.",
                    "The restaurant name and tax rates come from your settings, so nothing has to "
                    "be edited by a developer when they change.",
                    "Prints over Bluetooth to a standard ESC/POS thermal printer — not a PDF you "
                    "have to save and print separately.",
                ],
                "tech": "Receipts can be reopened at any time from the order history, which settles "
                        "most billing disputes in a few seconds.",
            },
        ],
    },
    {
        "id": "tablet",
        "no": "04",
        "title": "Tablet stations",
        "lead": "A larger screen removes steps from the job, not just pixels.",
        "device": "tablet",
        "screens": [
            {
                "img": "tablet-13-order-taking.png",
                "name": "Order station",
                "lead": "Menu on the left, the running order permanently visible on the right.",
                "points": [
                    "No opening and closing a basket, which measurably shortens the time to take "
                    "a large table's order.",
                    "The running total stays in view, so a server can advise a group as they order.",
                    "Well suited to a fixed station near the pass, or a counter service setup.",
                ],
                "tech": "The layout adapts to whatever screen it finds, so the same tablets can be "
                        "redeployed as the restaurant changes.",
            },
            {
                "img": "tablet-12-tables.png",
                "name": "Floor plan on a tablet",
                "lead": "The whole dining room without scrolling.",
                "points": [
                    "Navigation moves to the side of the screen, where a hand holding a tablet "
                    "naturally rests.",
                    "More tables fit at once, which suits a host stand managing seating.",
                ],
                "tech": "Column count adjusts to the screen automatically — nothing to configure.",
            },
            {
                "img": "tablet-15-order-detail.png",
                "name": "Bill detail on a tablet",
                "lead": "Dishes and totals side by side.",
                "points": [
                    "A manager can review an entire table without scrolling, which makes checking "
                    "a disputed bill quick.",
                    "The actions that matter — send to kitchen, add dishes, take payment — sit together.",
                ],
                "tech": "Identical to the phone version in behaviour, so staff move between devices "
                        "without retraining.",
            },
        ],
    },
    {
        "id": "admin",
        "no": "05",
        "title": "Management and reporting",
        "lead": "The back-office work, on a computer where it is comfortable to do.",
        "device": "web",
        "screens": [
            {
                "img": "web-18-dashboard.png",
                "name": "Dashboard",
                "lead": "Open it and know how the restaurant is doing right now.",
                "points": [
                    "The top bar answers the operational questions: how many bills are open, how many "
                    "tables are in use, how much work the kitchen still has.",
                    "Today's takings, number of bills and average spend per bill, without exporting anything.",
                    "The hourly chart shows when your rush actually happens, which is the basis for "
                    "sensible staff rotas.",
                    "Best sellers and the split between cash, QR and card are on the same screen.",
                ],
                "tech": "Figures refresh as bills close, so the dashboard is accurate at any point "
                        "during service rather than only after cashing up.",
            },
            {
                "img": "web-24-reports.png",
                "name": "Sales reports",
                "lead": "Look back over any period you choose.",
                "points": [
                    "Today, the last seven days, this month, or any custom date range.",
                    "Separates food revenue from discounts, service charge and VAT, so you can see "
                    "exactly how the net figure was reached.",
                    "Ranks dishes and summarises revenue by category — the numbers you need before "
                    "changing a menu or a price.",
                ],
                "tech": "All figures are calculated from the recorded bills, so a report can always "
                        "be traced back to individual transactions.",
            },
            {
                "img": "web-21-menu-management.png",
                "name": "Menu management",
                "lead": "The one thing a restaurant changes daily: what is available.",
                "points": [
                    "A single switch takes a dish off sale across every device instantly.",
                    "A counter shows how many dishes are currently switched off, so nothing stays "
                    "hidden after the delivery arrives.",
                    "Categories are managed separately, and a category still holding dishes cannot "
                    "be deleted by accident.",
                ],
                "tech": "Kitchen staff and servers can mark items sold out themselves; only managers "
                        "can change prices and details.",
            },
            {
                "img": "web-22-menu-form.png",
                "name": "Adding and editing dishes",
                "lead": "Including the option groups guests choose from.",
                "points": [
                    "Set which choices are compulsory and how many can be picked.",
                    "Give each extra its own price, so add-ons are charged consistently.",
                    "Record an approximate preparation time for future kitchen planning.",
                ],
                "tech": "No technical knowledge required — this is the same form used to build "
                        "the sample menu in this document.",
            },
            {
                "img": "web-23-staff.png",
                "name": "Staff accounts",
                "lead": "Who can do what, controlled in one place.",
                "points": [
                    "Filter by role and see the headcount for each at a glance.",
                    "Change someone's role, suspend an account temporarily, or remove it entirely.",
                    "An account cannot delete itself, and only an administrator can remove staff.",
                ],
                "tech": "Suspending an account is instant and does not affect the bills that person "
                        "already handled.",
            },
            {
                "img": "web-25-settings.png",
                "name": "Restaurant settings",
                "lead": "Tax and service rates belong to the business, not to the software.",
                "points": [
                    "Restaurant name, VAT rate and service charge are all editable, and apply to "
                    "bills opened afterwards.",
                    "Supports menus priced with VAT already included — the tax is shown separately "
                    "rather than added on top.",
                    "The restaurant name here is what prints on the receipt.",
                ],
                "tech": "Changing a rate does not disturb bills already open, so nothing changes "
                        "under a guest mid-meal.",
            },
            {
                "img": "web-30-customers.png",
                "name": "Customers and loyalty points",
                "lead": "Attaching a guest to a bill is optional, and the system keeps their "
                        "history and points balance without any extra work.",
                "points": [
                    "Search by name or phone number, or add a new customer from this screen.",
                    "See every customer's points balance in one list, then open one to view "
                    "their full purchase history.",
                ],
                "tech": "Points are only credited once a bill is paid in full, so a guest paying "
                        "in several instalments is never credited twice.",
            },
            {
                "img": "web-31-customer-detail.png",
                "name": "A customer's purchase history",
                "lead": "See exactly what a returning guest has ordered before.",
                "points": [
                    "A full list of past bills, with amount and date.",
                    "Remaining points can be redeemed for a discount immediately at the till.",
                ],
                "tech": "Redeeming points reduces what still has to be collected without changing "
                        "the bill's recorded total.",
            },
            {
                "img": "web-32-audit-log.png",
                "name": "Audit log",
                "lead": "Every action that touches money is recorded, and nothing in the interface "
                        "can edit or delete that record.",
                "points": [
                    "Covers order cancellations, refunds, menu price changes and manual stock "
                    "adjustments alike — each entry names who did it and why.",
                    "Filter by action type and date range, and export to CSV for the accounting "
                    "team in one click.",
                    "Restricted to the web admin screen, since reviewing a long log needs a wide "
                    "screen, not a phone.",
                ],
                "tech": "Writing the log entry happens in the same database transaction as the "
                        "change itself — if the log write fails, the change is rolled back too.",
            },
            {
                "img": "web-19-tables.png",
                "name": "Floor plan on the web",
                "lead": "Owners can see the room without standing in it.",
                "points": [
                    "Exactly the same information the servers see, so there is no second version "
                    "of the truth.",
                    "Useful for an owner covering more than one site, or working from the office.",
                ],
                "tech": "Works in any modern browser with nothing to install.",
            },
            {
                "img": "web-20-orders.png",
                "name": "Orders on the web",
                "lead": "Follow the whole service from one screen.",
                "points": [
                    "The same filters as the floor staff use, with more room to read them.",
                    "Open any bill to review or correct it.",
                ],
                "tech": "Refreshes automatically as bills are opened and settled.",
            },
            {
                "img": "web-17-login.png",
                "name": "Sign in on a computer",
                "lead": "The same account works on every device.",
                "points": [
                    "One set of credentials for phone, tablet and browser.",
                    "Nothing to install on a manager's laptop — it is a web address.",
                ],
                "tech": "New staff can be onboarded in the time it takes to create an account.",
            },
        ],
    },
    {
        "id": "self-order",
        "no": "06",
        "title": "Customers ordering themselves",
        "lead": "The one screen guests open on their own phone — with no login anywhere in sight",
        "device": "phone",
        "screens": [
            {
                "img": "phone-35-self-order-menu.png",
                "name": "The menu a guest sees after scanning",
                "lead": "Scan the code on the table and the menu is there — no app to install, no account to create",
                "points": [
                    "The header names the table and its zone, so a guest can confirm they scanned the right one",
                    "There is deliberately no back button: guests arrive here first, and going back would drop them into the staff area",
                    "A badge in the corner shows how many items this table has already ordered",
                ],
                "tech": "It is a separate module that never touches the staff session layer, yet it reuses the "
                        "same menu cards, category bar and option sheet the waiter app is built from",
            },
            {
                "img": "phone-36-self-order-cart.png",
                "name": "The guest's cart",
                "lead": "Quantities are adjustable before anything reaches the kitchen",
                "points": [
                    "Tapping the same dish again merges into one line and raises the quantity instead of repeating it",
                    "Pressing minus at a quantity of one removes the line, so there is no separate delete button to mis-tap",
                    "The total is clearly marked as excluding service charge and VAT, which are added once the order is sent",
                ],
                "tech": "It reuses the same cart-line type as the staff cart, so the merging rule "
                        "(same dish, same options, same note) comes for free rather than being written twice",
            },
            {
                "img": "phone-37-self-order-current-order.png",
                "name": "What the table has ordered so far",
                "lead": "Guests can check their own bill without flagging anyone down",
                "points": [
                    "Per-dish kitchen status (queued, cooking, ready) — the same status the staff see",
                    "A full bill breakdown including service charge and VAT",
                    "Items a waiter entered earlier appear in the same list, because it is genuinely the same order",
                ],
                "tech": "Staff and customer personal details (server name, customer name and phone) are stripped "
                        "from the data before it is ever sent to the public page",
            },
            {
                "img": "phone-39-table-qr-sheet.png",
                "name": "Staff side — view and rotate a table's QR",
                "lead": "Long-press a table on the floor plan and pick \u201cView self-order QR\u201d",
                "points": [
                    "Shows the real QR code for that table, with a copy-link button for producing table tents",
                    "A \u201cRegenerate QR\u201d action (managers and admins only) for when a printed code leaks",
                    "The moment it is regenerated the old link stops working — no waiting for an expiry",
                ],
                "tech": "The link is derived from the domain the app is actually served from, so it is correct "
                        "both on a local machine and on a live domain with no extra configuration",
            },
        ],
    },
]

CLOSING = {
    "found_bugs": [
        ("Money is handled exactly",
         "All amounts are stored as whole units internally, which removes the rounding drift that "
         "creeps into systems using decimal arithmetic. A bill split three ways still balances."),
        ("The server is the source of truth",
         "Devices display totals, but the price charged is always calculated centrally. "
         "A tampered or out-of-date device cannot change what a guest pays."),
        ("Permissions are enforced, not just hidden",
         "Restricting a screen in the interface is only the first layer. Requests made directly "
         "to the system are checked again against the signed-in role."),
        ("Behaviour is checked automatically",
         "558 automated checks run against the system, including audit-trail coverage for every "
         "action that touches money and a full end-to-end walk from seating a table to the sale "
         "appearing in the daily report."),
    ],
    "next": [
        "A formal end-of-shift Z-report, exportable as an official document",
        "Multi-branch support on PostgreSQL, with consolidated reporting across sites",
        "Advance table reservations",
        "Automatic e-Tax invoice filing straight to the tax authority",
        "A connected PromptPay payment gateway that confirms payment automatically "
        "(today the cashier confirms it manually)",
    ],
}


LABELS = {
    "lang": "en",
    "font": "NotoSansThai",
    "cover_foot_left": "Feature and screen guide",
    "cover_foot_right": "Every screenshot taken from the working system",
    "footer": "PaynEat POS — Feature and screen guide",
    "overview_kicker": "OVERVIEW",
    "overview_title": "What the system does, and what it fixes",
    "problem_title": "The problem",
    "problem_body": "Four groups of people work a restaurant at the same time, on four different "
                    "kinds of device, all needing the same information. The gaps between them — a "
                    "lost ticket, a miscounted bill — are what cost the business money.",
    "roles_title": "Who uses what",
    "roles_headers": ("Role", "Device", "Day-to-day use"),
    "toc_title": "What is in this document",
    "screens_suffix": "screens",
    "shots_note": "Every screenshot in this document is rendered directly from the working system, "
                  "not drawn as a mock-up. The interface shown is Thai; an English interface is "
                  "available on request.",
    "section_prefix": "SECTION",
    "tech_label": "In practice",
    "closing_no": "07",
    "closing_title": "Why you can rely on it",
    "closing_lead": "How the system protects your revenue, and what is planned next",
    "closing_callout_title": "Designed around the places POS systems usually go wrong",
    "closing_callout_body": "Most point-of-sale problems are not dramatic failures. They are a bill "
                            "that is a few satang out, a void nobody can account for, or a device "
                            "showing yesterday's prices. Each of those was treated as a requirement "
                            "rather than an afterthought.",
    "tests_title": "Verified automatically",
    "tests_headers": ("Area", "Checks", "What is covered"),
    "tests_rows": [
        ("Server", "292 checks",
         "Run against a real database, including full audit-trail coverage of every action that "
         "touches money (shift open/close, payments, promotion changes) and one check that walks "
         "a full service from seating a table through to the sale appearing in the daily report"),
        ("Application", "346 checks",
         "Bill calculation (VAT, service charge, promotions), order handling, role permissions, "
         "screen behaviour, and a screenshot test for every screen shown in this document"),
    ],
    "next_title": "Planned next",
    "closing_note": "What is not built yet is listed openly, because knowing the boundaries of a "
                    "system matters as much as knowing its features.",
}
