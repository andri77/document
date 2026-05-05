# Interview Preparation: Automation Tester — EY Insurance Platforms

**Role:** Partner - QA / Automation Test Engineer (SmartCOMMs)
**Team:** Customer Comms Outbound — Insurance Platforms
**Duration:** 6 months FTE (extension likely)
**Hiring Manager:** Carlo Cristillo

---

## Role at a Glance

- Agile squad (6 squads × ~10 people: 1 IM, 2 BAs, 3 Devs, 4 QAs)
- Testing outbound comms — print, email, SMS — for Policy and Claims systems
- Tech stack: SmartCOMMs, Cucumber/Ruby/Selenium, BDD, Git, CI/CD, JIRA/Confluence

---

## Section 1: BDD & Cucumber (Mandatory)

### Q1: Walk me through how you structure a BDD automation framework from scratch.

**Sample Answer:**
> I start by defining feature files in Gherkin — Given/When/Then — written with BAs and product owners to capture business intent. Each feature file maps to a step definitions file where I implement the actual test logic. I organise the framework with a clear folder structure: `features/`, `step_definitions/`, `support/` (hooks, world context), and `pages/` for page objects. I wire it together with a `env.rb` or configuration file that handles environment variables and driver setup. Hooks (`Before`/`After`) manage setup/teardown. I ensure each step is atomic and reusable so multiple scenarios can share steps without duplication.

### Q2: How do you handle flaky tests in a Cucumber regression suite?

**Sample Answer:**
> First I isolate the flaky test and reproduce it reliably. Common causes I look for: timing issues (solved with explicit waits, never `sleep`), data dependencies (tests sharing state — solved by independent test data per scenario), and environment instability. I add retry logic at the runner level sparingly — it masks root causes. I tag flaky tests with `@quarantine` and track them in JIRA so the team is aware they're under investigation. I always fix root cause before removing the quarantine tag.

### Q3: What is the difference between `Background`, `Scenario Outline`, and `Examples` in Cucumber?

**Sample Answer:**
> `Background` runs before every scenario in a feature file — good for common preconditions like logging in. `Scenario Outline` is a template scenario parameterised with `<placeholders>`. `Examples` is the data table that provides concrete values for each `Scenario Outline` run. Each row in `Examples` produces one scenario execution. I use outlines for data-driven validation — e.g., testing multiple insurance document types with the same validation steps.

---

## Section 2: Test Automation — Ruby, Selenium, Frameworks

### Q4: Describe your experience with Ruby/Cucumber and Selenium for UI automation.

**Sample Answer:**
> I've used Ruby with Cucumber and Selenium WebDriver as my primary stack for [X] years. I manage dependencies via `Bundler` and `Gemfile`. For browser control I use `selenium-webdriver` gem, and I wrap it in a Page Object pattern — each page class exposes methods that encapsulate selectors and interactions, keeping tests clean and maintainable. I've integrated Capybara for higher-level DSL when needed. I run suites in parallel using `parallel_tests` gem to reduce pipeline time.

### Q5: How do you implement the Page Object Model in Ruby?

**Sample Answer:**
> Each page gets its own class. Locators are constants or private methods inside the class, not scattered in step definitions. Public methods represent user actions — `login(user, pass)`, `submit_claim()`. Steps call page methods, not raw Selenium commands. This means if a selector changes, I update one file, not 50 step definitions. I also use a `BasePage` class with shared helpers like `wait_for_element`, `scroll_to`, and `take_screenshot`.

### Q6: How do you validate PDF or print-ready documents in automation?

**Sample Answer:**
> For SmartCOMMs-generated PDFs I've used tools like `pdf-reader` gem in Ruby or `pdfplumber`/`PyPDF2` in Python to extract text and validate content against expected business rules. I check key fields — policy number, customer name, dates, premium amounts — by parsing the PDF text. For layout validation I use visual regression tools (like Applitools) to compare rendered output against a baseline. For HTML previews I use standard DOM assertions via Selenium.

### Q7: How do you keep automated test scripts stable and reusable?

**Sample Answer:**
> Three practices: (1) **Selector discipline** — I prefer `id`, `data-testid`, `aria-label` over XPath or positional selectors. (2) **No hard-coded waits** — always explicit waits with sensible timeouts. (3) **Modular design** — shared helper methods in utilities, not duplicated in every test. I also run a weekly maintenance pass reviewing any tests that failed for non-product reasons, and I refactor them before they become technical debt.

---

## Section 3: API Testing (SoapUI, Postman, XML)

### Q8: How do you approach API testing for complex XML-based insurance systems?

**Sample Answer:**
> I start by understanding the schema — XSD or WSDL for SOAP services. In SoapUI I import the WSDL to auto-generate request templates, then build positive, negative, and boundary test cases. For XML validation I assert against schema using SoapUI's XPath/XQuery assertions. For complex structures I extract values with XPath — e.g., checking a specific node's value inside a nested claims response. In Postman I use `pm.response.json()` or `xml2Json()` for assertions in the test scripts tab, chained with environment variables for dynamic values.

### Q9: What is the difference between SOAP and REST API testing?

**Sample Answer:**
> SOAP uses XML envelopes, WSDL contracts, and typically HTTP POST only. Validation focuses on XML structure, namespace correctness, and SOAP faults. REST is stateless, uses standard HTTP verbs (GET/POST/PUT/DELETE), and typically returns JSON (sometimes XML). REST testing is more flexible — I validate status codes, response bodies, headers, and sometimes HAL links. For insurance document systems, SOAP is common in legacy policy systems, REST in newer microservices — I'm comfortable with both.

### Q10: How do you test APIs in a CI/CD pipeline?

**Sample Answer:**
> I export Postman collections and run them via Newman in the pipeline (`newman run collection.json -e env.json --reporters cli,junit`). JUnit output integrates with build tools like GitHub Actions to fail the build on assertion errors. For SoapUI I use the command-line runner (`testrunner.sh`) or Maven plugin. I separate smoke tests (fast, core paths) from full regression to keep pipeline feedback loops tight.

---

## Section 4: CI/CD & Version Control

### Q11: How do you use Git in a team testing environment?

**Sample Answer:**
> I follow a branching strategy — feature branches off `main` or `develop`, PRs with peer review before merge. For test code I apply the same discipline as production code: meaningful commit messages, small focused commits, no committing commented-out tests or debug code. I use `git bisect` when tracking down when a test regression was introduced. I also maintain a `.gitignore` that excludes test reports, screenshots, and local config to keep the repo clean.

### Q12: Describe your experience with CI/CD tools like GitHub Actions.

**Sample Answer:**
> I've set up GitHub Actions workflows that trigger on PR and on merge to main. The workflow runs linting, then the smoke test suite, then full regression in parallel jobs. I use matrix strategy to run tests across multiple environments (dev, staging) simultaneously. Artifacts — test reports, screenshots on failure — are uploaded and retained for 7 days. I've also configured Slack notifications for build status so the team has visibility without checking GitHub constantly.

---

## Section 5: Agile / Scrum Ceremonies

### Q13: How do you contribute to Agile ceremonies as a QA engineer?

**Sample Answer:**
> In **sprint planning** I estimate test effort alongside devs and flag stories with unclear acceptance criteria before sprint start — not during. In **daily standups** I report blockers immediately, not just "testing story X." In **backlog refinement** I add test considerations to acceptance criteria and identify edge cases early. In **retrospectives** I bring data — escaped defects, flaky test counts, automation coverage delta — not just feelings. I also run **three amigos** sessions on complex stories with the BA and dev to align on testable requirements upfront.

### Q14: How do you manage test progress reporting in an Agile squad?

**Sample Answer:**
> I use JIRA dashboards with filters showing: total test cases per story, pass/fail/blocked counts, open defects by severity, and automation coverage percentage. I update defect status daily. In sprint review I present coverage trends — not just "all tests passed" but what the tests actually cover. I escalate blockers in the daily standup and in Confluence I maintain a living test summary document updated each sprint.

---

## Section 6: SmartCOMMs & Insurance Domain

### Q15: What do you know about SmartCOMMs (Smart Communications)?

**Sample Answer:**
> SmartCOMMs is a customer communications management (CCM) platform used to generate personalised insurance documents — policies, renewal notices, claims correspondence — across print, email, and SMS channels. It uses template-based content with variable data merged from source systems (policy admin, claims). Testing it involves validating that business rules are correctly applied to document generation, content is accurate for each customer scenario, and output is formatted correctly across channels. I understand that regression testing in SmartCOMMs requires tight coverage of business rules because a template change can affect thousands of customer documents.

### Q16: How would you approach automation feasibility assessment for a SmartCOMMs project?

**Sample Answer:**
> I evaluate four factors: (1) **Stability** — are the document templates and data sources stable enough that tests won't break every sprint? (2) **ROI** — are these regression scenarios run frequently enough to justify automation investment? (3) **Tooling** — can we access SmartCOMMs output (PDF/HTML) programmatically for assertions? (4) **Data** — can we generate or provision realistic test data that covers the business rules? I document findings in a feasibility report with a recommended approach, estimated effort, and risks. I'd recommend automating high-volume, frequently-run regression cases first — policy renewals, standard claims letters — before tackling edge cases.

### Q17: How do you test outbound communications (email, SMS, print) for correctness?

**Sample Answer:**
> For **email** I use tools like Mailosaur or a test inbox API to capture sent emails and assert on subject, body content, links, and attachments. For **SMS** I use a test gateway that captures messages by test phone number. For **print/PDF** I extract text and validate against expected content rules — policyholder name, address, policy number, correct dates. I also validate formatting — page breaks, headers/footers — using visual regression. I test both the happy path (standard customer) and edge cases (unusual characters in names, long addresses, zero-value claims).

### Q18: What is context-based and risk-based testing?

**Sample Answer:**
> **Context-based testing** means adapting your testing approach to the specific project context — team size, tech stack, risk profile, timeline — rather than applying a one-size-fits-all process. For insurance documents the context is high compliance risk and customer impact, so I prioritise thoroughness over speed. **Risk-based testing** means prioritising test coverage by likelihood and impact of failure. In a claims system, an incorrect payout amount has higher risk than a formatting issue, so I allocate more testing effort there. I use a risk matrix with stakeholders to agree on priorities at the start of each sprint.

---

## Section 7: Coaching & Mentoring

### Q19: How have you coached junior or mid-level testers?

**Sample Answer:**
> I run weekly 1:1s with junior testers to review their test cases and give specific, actionable feedback — not just "this is wrong" but "here's why and here's the pattern to use instead." I pair with them on complex automation tasks rather than just reviewing code after the fact. I maintain a team wiki with patterns, anti-patterns, and worked examples. I also give juniors ownership of non-critical automation tasks so they build confidence, then increase scope as they demonstrate capability. I track their growth and advocate for their promotion when they're ready.

### Q20: How do you establish and enforce testing standards in a team?

**Sample Answer:**
> I establish standards collaboratively — I don't hand down rules, I workshop them with the team so there's buy-in. We document agreed patterns in Confluence: selector strategies, naming conventions, assertion patterns, test data management rules. I embed standards in code review — PRs for test code get the same review rigour as production code. I use linting (e.g., RuboCop for Ruby) to enforce style automatically. Monthly I review the test suite health metrics with the team and use them to drive targeted improvements.

---

## Section 8: Documentation & Communication

### Q21: What does good test documentation look like to you?

**Sample Answer:**
> A test case should be understandable by a BA or developer — not just a tester. Each case has: clear preconditions, specific input data, numbered steps, expected result, and actual result (after execution). Bug reports include: steps to reproduce, expected vs actual, environment, severity, and a screenshot or log. I maintain a test summary after each sprint: coverage achieved, defects found/resolved, risks outstanding. I avoid documentation for its own sake — if a test is automated, the feature file IS the documentation.

### Q22: How do you communicate testing risks to stakeholders?

**Sample Answer:**
> I translate technical risk into business impact — not "we have 12 failing tests" but "3 of those failures affect the claims correspondence module which sends 2,000 letters a week — I recommend we don't release until these are resolved." I surface risks early — in sprint planning if I see insufficient time for testing, in standups if I hit a blocker. I document risks in a JIRA risk register with likelihood, impact, and mitigation. I also flag to the IM immediately if a defect's severity warrants a conversation about release readiness.

---

## Section 9: Situational / Behavioural Questions

### Q23: Tell me about a time you found a critical defect late in a sprint.

**Sample Answer (STAR):**
> **Situation:** Two days before sprint end, regression testing on a policy renewal document found that the premium calculation was using the wrong effective date for a specific customer segment.
> **Task:** Determine severity, communicate impact, and decide whether to block the release.
> **Action:** I reproduced it with three different data scenarios to confirm it wasn't test data specific. I documented it with evidence and immediately escalated to the IM and BA. We ran an emergency three-amigos with the dev lead to understand fix complexity. Fix was a 2-hour code change.
> **Result:** Fixed same day, re-tested, released on schedule. I added this scenario to the permanent regression suite to prevent recurrence.

### Q24: How do you handle disagreements with developers about whether something is a defect?

**Sample Answer:**
> I go back to the acceptance criteria — that's the arbiter, not either of our opinions. If it's ambiguous I pull in the BA for a three-way clarification. I never make it personal; I frame it as "let's align on what the business expects." If after discussion the behaviour is intentional but undocumented, I ask for the AC to be updated and raise a separate story to address the user experience gap if there is one. I've found that most disagreements come from unclear requirements, not bad faith.

### Q25: What does "done" look like for a test automation task?

**Sample Answer:**
> Done means: (1) automated tests cover the defined acceptance criteria, (2) tests pass consistently in CI — not just on my machine, (3) code has been peer reviewed, (4) tests are integrated into the regression suite and running in the pipeline, (5) test coverage delta is documented in the sprint summary. Not done: tests passing locally only, tests skipped or quarantined without a tracking ticket, or automation added without removing the equivalent manual regression case from the suite.

---

## Questions to Ask the Interviewer

- How mature is the current automation suite — percentage of regression automated vs manual?
- What is the primary blocker the team faces in expanding SmartCOMMs test automation today?
- How closely do QAs collaborate with developers on acceptance criteria — is three-amigos practiced?
- Is there an existing BDD framework I'd be working within, or greenfield opportunity?
- What does the definition of done look like for automation tasks in your squads today?
- How is automation maintenance factored into sprint capacity?
- What is the biggest quality risk on the Customer Comms Outbound program right now?

---

## Key Themes to Reinforce Throughout

| Theme | Talking Point |
|-------|--------------|
| BDD mastery | Lead with Cucumber examples, step reuse, living documentation |
| Insurance domain | Show understanding of policy, claims, document generation risk |
| Stability focus | Selector discipline, flaky test management, maintenance approach |
| Senior presence | Coaching, standards, risk communication to stakeholders |
| Hands-on delivery | Real tools (SoapUI, Postman, pdf-reader, GitHub Actions) not just concepts |
| SmartCOMMs | Even if limited direct experience — frame PDF/document validation expertise |

---

*Prepared for interview with Carlo Cristillo — EY Insurance Platforms — Customer Comms Outbound*
