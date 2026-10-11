# Play Console — remaining manual steps

Ordered checklist of the manual Google Play Console work left after the drafts
in this folder are ready. Tick items off from top to bottom.

---

## 0. Before opening Play Console

- [ ] Replace the placeholders in `privacy-policy.html`: `[EFFECTIVE_DATE]`
      and `[YOUR_EMAIL]` (the same email you will publish in the store listing).
- [ ] Host `privacy-policy.html` at a public, stable URL (for example GitHub
      Pages, Firebase Hosting, or your own site). Play requires a live privacy
      policy URL, and it must not require a login.
- [ ] Confirm the contact email is monitored — it is the address used for data
      deletion requests.

## 1. Create the app in Play Console

- [ ] Create a new app; set the default language and the app name
      **QuitDrink Ai: Sober Tracker**.
- [ ] Accept the Play Console developer agreements and the U.S. export
      declarations.
- [ ] Note the package name (`quit_drinking` / the `applicationId` used by the
      release build).

## 2. Store listing (from `listing.md`)

- [ ] Paste the **title**, **short description**, and **full description**.
- [ ] Enter the **app category** (Health & Fitness) and add tags/keywords.
- [ ] Add **contact details** (email required; website optional).
- [ ] Upload the **512 × 512 app icon**.
- [ ] Upload the **1024 × 500 feature graphic**.
- [ ] Upload the **6 phone screenshots** (see `listing.md`) in the planned
      order with short, calm captions.
- [ ] Upload any tablet / large-screen screenshots if you plan to support them.
- [ ] Fill in the **"What's new"** release note.

## 3. App content declarations

- [ ] **Privacy policy:** paste the hosted URL.
- [ ] **Data safety:** complete the form using the answers in `data-safety.md`.
      Keep the "data collected", "shared", "encrypted in transit", and
      "deletion" answers consistent with that file.
- [ ] **Ads:** declare that the app contains **no ads**.
- [ ] **Content rating questionnaire:** complete it honestly (this is a
      substance-related wellness app; answer the questions truthfully — the
      rating will follow from your answers).
- [ ] **Target audience and content:** set 18+ / adults; the app is not for
      children.
- [ ] **News app:** declare that it is **not** a news app.
- [ ] **Health apps declaration:** declare the app is a wellness/self-tracking
      tool, not a medical device and not offering treatment. Add the required
      notes from `data-safety.md`.
- [ ] **Sensitive data / health content declaration** if prompted.
- [ ] **Financial features:** declare that no financial features are offered
      (the money-saved tool is a local estimate, not a financial service).
- [ ] **Government apps:** declare that the app is **not** a government app.
- [ ] **Data deletion:** confirm the in-app reset path and the contact email.

## 4. Build and signing

- [ ] Confirm the AI key is not committed and there is no secret in the release
      build (`lib/config/api_config.dart` must stay git-ignored; the example
      file must hold only the placeholder).
- [ ] Build a release **Android App Bundle (.aab)** with your own keystore.
- [ ] Enroll in **Play App Signing**.
- [ ] Upload the bundle to the **internal testing** track.

## 5. Verify on a real device (internal test)

- [ ] Install from the internal track and open the app.
- [ ] Check the onboarding health notice ("Before You Begin") shows.
- [ ] Check the daily reminder can be enabled, fires, and can be turned off.
- [ ] Check the AI Friend chat works (or shows offline replies) and the "not a
      medical professional" disclaimer is visible.
- [ ] Verify **Settings → Reset All Data** truly clears data and returns to
      onboarding, and that the privacy policy link opens the hosted URL.
- [ ] Confirm the privacy policy URL opens without a login on a phone.

## 6. Review and release

- [ ] Complete the **Closed testing** requirement (if required for a new
      personal developer account) and gather tester feedback.
- [ ] Fix any console warnings in **App content** and **Store listing**.
- [ ] Promote to **Open testing** and then **Production**.
- [ ] Complete the **content review** questionnaire and submit for review.
- [ ] After approval, roll out to the chosen countries and percentages.

---

## Later (only if real billing is added)

- [ ] Set up an in-app product / managed purchase for the Pro upgrade.
- [ ] Update the **Privacy Policy** (purchases section) and **Data safety**
      (purchases are handled by the store; no card details reach the app).
- [ ] Update the **Terms of Service** and the Pro upgrade screen copy to match
      the live store billing.
