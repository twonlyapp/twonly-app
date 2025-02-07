# twonly

Don't be lonely, get twonly! Send pictures to a friend in real time and be sure you are the only two people who can see them.


## TODOS bevor first beta
- Add no_screenshot plugin: https://pub.dev/packages/no_screenshot
- Bei mehreren neu Empfangen Nachrichten fixen
- Settings
    - Delete and Block active users
- Onboarding Slide, Text und Animationen
- MessageKind -> Ausbauen?
- Nachrichten nach 24h Stunden löschen
- Real deployment aufsetzen direkt auf Netcup?
- Pro Invitation codes

## Later todos
- Videos
- Sealed Sender
- Settings
    - Profilbilder erstellen.
- Pro Version
- Media Shower -> Recap of the day
- Send normal images via twonly



## Pro Version

- Send and receive unlimited pictures
- This includes a free pro version for your twonly partner!
- Get up to 3 tokens 
- Get for your twonly partner a second a additional pro version



## Features

This app was started because of the three main features I missed out by popular alternatives.


## Background Notification

The server will first try to send via an open websocket connection.
If not available then it sends a wakeup via FCM. This will trigger the app to reopen the websocket.

### Three to rule them all.

1. Security by design: No one except your device can access your data.
2. Privacy by design: The server only knows your username and public key.
3. User-friendliness: Decide for your own :)

## Bug-Bounty

twonly offers a Bug Bounty. Depending on the criticality the bounty can go up to 50€ (more later,
this is out of my own pocket :/).
