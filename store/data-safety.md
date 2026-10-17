# Play Console — Data Safety form (draft answers)

Draft responses for the Google Play "Data safety" section, based on what the
app's code actually does. Google's definitions matter here: **"collected"
means data that leaves the device** and is transmitted off it. Data that only
lives in the app's private storage on the phone is **not** counted as
collected.

---

## Top-level answers

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Do you provide a way for users to request that their data be deleted? | **Yes** |

---

## Data types — collected

### 1. App activity → App interactions

- **Collected:** Yes
- **Shared:** Yes — with Google (Firebase Analytics is a third-party SDK; data
  is processed by Google).
- **Processed ephemerally:** No
- **Required or optional:** Data collection is automatic (not optional to
  collect). There is no in-app analytics opt-out toggle.
- **Purposes:** Analytics
- **What this covers:** Basic usage events such as the app being opened
  (`app_open`) and a daily reminder being scheduled (`reminder_scheduled`).
  No name, email, contact details, journal text, reason text, weight values,
  or chat text is included.

### 2. Device or other IDs → Device or other IDs

- **Collected:** Yes
- **Shared:** Yes — with Google (Firebase Analytics app-instance identifier).
- **Processed ephemerally:** No
- **Required or optional:** Automatic.
- **Purposes:** Analytics
- **What this covers:** Firebase Analytics' standard app-instance identifier
  and related technical identifiers used to group analytics sessions. The app
  also generates its own random UUID "device ID" on first launch; that ID is
  stored **only on the device** and is not tied to any account, name, or email.

### 3. Messages → Other in-app messages (AI Friend chat)

- **Collected:** Yes
- **Shared:** Yes — with Google, solely to generate a reply. Messages are sent
  through Firebase AI Logic to Google's Gemini.
- **Processed ephemerally:** No (the request is sent to Google to produce a
  response; we do not store the messages on our own servers).
- **Required or optional:** Optional — only occurs if the user uses the AI
  Friend chat and an AI service is configured. Core features work offline.
- **Purposes:** App functionality
- **What this covers:** The text the user types in the AI Friend chat, plus the
  recent conversation history sent along with it, shared with Google (Gemini,
  through Firebase AI Logic) to generate a reply. The user's own chat history
  is stored on the device and can be cleared in the chat screen.

---

## Data types — NOT collected (declare as not collected)

These are either never gathered or stay entirely on the device, so they must
not be declared as collected:

- **Name, email address, phone number, address, user IDs:** Not collected — no
  account is created and none of these are requested.
- **Health and fitness (weight, check-in history, sobriety date):** Stored only
  in the app's private storage on the device. Not transmitted off the device,
  so **not collected**.
- **Personal notes / journal entries / saved reasons:** Stored only on the
  device. Not collected.
- **Financial info / purchase history:** Not collected and not shared. **No
  purchase information is collected** — the app has no billing integration and
  processes no payments, so there are no purchase records to declare. The
  money-saved calculator is a local estimate only; it is not a financial
  service and no payment data exists.
- **Photos, videos, files, audio, contacts, calendar:** Not collected.
- **Location:** Not collected.
- **Web browsing, in-app search history, other user-generated content:**
  Not collected.
- **Advertising ID:** Not collected or used; the app serves no ads.

---

## Data usage and handling

- **Sharing summary:** Data is shared only with service providers needed to run
  the app — **Google (Firebase Analytics)** for usage analytics and **Google
  Gemini (through Firebase AI Logic)** for AI Friend replies. User chat
  messages are shared with Google for app functionality. Data is not sold.
- **Advertising / marketing:** Analytics data is not used for advertising, and
  the app contains no ads.
- **Security practices:**
  - Data in transit is encrypted (all network calls use HTTPS/TLS —
    Firebase and Google's Gemini endpoint through Firebase AI Logic).
  - AI chat requests are protected by **Firebase App Check**, which verifies
    that they come from the app.
  - Users can request deletion (see below).
  - No account or login system exists, so there is no account data to protect.
- **Data retention:** On-device data is kept until the user deletes it in the
  app or uninstalls the app. Analytics data held by Google follows Google's
  retention settings.

---

## Data deletion

- **Can users request data deletion?** Yes.
- **Deletion mechanism:**
  1. **In-app:** *Settings → Reset All Data* clears the app's local data
     (sobriety date, check-ins, reasons, journal, weight log, chat history, and
     preferences) and cancels scheduled reminders.
  2. **Uninstall:** removing the app deletes its private on-device storage.
  3. **Analytics data:** aggregate analytics data already recorded by Firebase
     is not removed by uninstalling; users can email **[YOUR_EMAIL]** to request
     deletion.
- **Deletion URL / contact:** the public privacy policy page
  (see `privacy-policy.html`) with the contact email **[YOUR_EMAIL]**.

---

## Health apps declaration — notes

- The app is a **wellness / self-tracking** tool for people reducing or
  stopping alcohol. It is **not a medical device** and makes no diagnostic or
  treatment claims.
- No health or fitness data is transmitted off the device. Weight entries,
  check-ins, and the sobriety counter are stored locally only.
- The app includes an in-app notice that it is **not medical advice**, warns
  that stopping heavy drinking suddenly can be dangerous, and points to
  emergency help (988 in the US, local emergency number elsewhere).
- **Data safety answers should stay consistent** with this: health/fitness
  data must remain marked as **not collected**, because it never leaves the
  device.
- If Play asks whether the app provides health-related features, answer
  honestly: it offers motivational support and self-tracking, not medical care
  or treatment. Be prepared to complete the Health apps declaration and, if
  prompted, the Sensitive data / health content declaration.

---

## Permissions reference (for consistency with the store form)

The Android manifest declares these permissions — none of which change the
answers above:

| Permission | Why |
| --- | --- |
| `INTERNET` | Firebase Analytics and the optional AI Friend chat |
| `POST_NOTIFICATIONS` | The optional daily reminder notification |
| `SCHEDULE_EXACT_ALARM` | Scheduling the daily reminder at a chosen time |
| `RECEIVE_BOOT_COMPLETED` | Re-scheduling the reminder after a restart |

No location, camera, microphone, contacts, or storage permissions are used.
