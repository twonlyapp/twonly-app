# Changelog

## 0.5.2

- Hotfix: Fixed an infinite loop involving delivery receipts

## 0.5.1

- Improve: Show delivery and read receipt indicators for text messages
- Improve: Backup screen clearer and easier to understand
- Improve: Show username above messages in group chats
- Fix: Background audio correctly pauses and resumes when viewing videos
- Fix: Sometimes old messages were being received as duplicates
- Fix: Multiple smaller bug fixes

## 0.5.0

- New: Update to Signal's new PQC-ready key agreement PQXDH
- New: Contact labels
- Fix: Multiple bug fixes
- Fix: Multiple black screens

## 0.4.0

- New: Encrypted Cloud Backup of Memories
- New: Passwordless Backup
- Fix: Performance issues

## 0.3.7

- Fix: Multiple UI issues

## 0.3.6

- Improve: Visibility of the verification badge

## 0.3.5

- Fix: Performance issue caused by an out-of-sync Signal session
- Fix: Multiple smaller bug fixes

## 0.3.3

- Fix: Multiple UI issues
- Fix: Camera initialization issue

## 0.3.2

- Fix: Multiple smaller performance and UI issues

## 0.3.1

- New: Promotion of sharing contacts when contact is new to twonly
- Improve: Onboarding of new users to the verification badges
- Improve: Better feedback when a QR code is scanned
- Fix: Shared contacts now correctly show the blue verification badge
- Fix: Suppressed link previews for scanned QR codes
- Fix: Black screen on iOS when a link is clicked
- Fix: Fixed size of the typing indicator to prevent the chat from glitching
- Fix: Push notifications are not shown for chats that are already open
- Fix: Multiple smaller performance and UI issues

## 0.3.0

- Improve: Design of some UI components
- Improve: Memories viewer shows state for batch operations and has improved performance
- Fix: Issue with background notifications on Android
- Fix: Changed minimum threshold for the user discovery to 3
- Fix: Multiple UI issues
- Fix: Auto-detect if FCM token does not work and trigger a reset

## 0.2.26

- New: Import images from the gallery
- Improve: Media files are now stored in the dedicated "twonly" album
- Improve: UI components adapt to native styling (iOS/Android)
- Fix: Migration issue that resulted in a corrupted backup mechanism
- Fix: Database issues causing messages to be lost or the database to be corrupted
- Fix: Permission view did not disappear after they were granted

## 0.2.23

- Improve: Smaller UI changes
- Fix: Some messages were not marked as opened.

## 0.2.20

- New: Adds an "Ask a Friend" button to new contact suggestions.
- New: Adds security profiles.
- Improve: Onboarding flow for new users.
- Improve: Flame restore experience.
- Improve: The blue verification checkmark now displays the total number of verifications.
- Fix: Issue with receiving messages when user closed app while decrypting
- Fix: Background message fetching reliability.
- Fix: Issue with focus changing when taking a picture
- Fix: Issues with the camera initialization

## 0.2.16

- Fix: Images not shown after opening due to cleanup

## 0.2.15

- Fix: Issue with opening directly in chats
- Fix: Multiple smaller issues

## 0.2.13

- New: Tutorial on how to use zoom.
- New: Manage storage view.
- Improve: Media thumbnails for faster loading.
- Fix: Some messages were not marked as opened.

## 0.2.12

- New: Automatically mark identical media as opened across all chats (Settings > Chats).
- Improve: Memories viewer redesigned with smoother animations and new quick-action controls.
- Fix: Reliability of receiving media files.

## 0.2.11

- New: Create custom shortcuts to quickly share images with pre-selected groups
- New: Seamless recovery for iOS reinstallations
- Improve: Redesigned snackbar notifications
- Improve: New backup mechanism to allow larger backup files
- Improve: Move keys into a centralized Rust-owned structure stored in secure storage
- Fix: Messages occasionally not received until app restart
- Fix: Multiple smaller issues

## 0.2.10

- Fix: Issue with push notifications on Android

## 0.2.9

- Improve: Make contact avatars clickable
- Fix: Messages occasionally not received until app restart
- Fix: Complete setup would sometimes get stuck

## 0.2.8

- Fix: App did not launch sometimes on Android

## 0.2.0

- New: Feature to find friends without a phone number
- New: The verification state is now transferred to the scanned user
- New: Registration setup to configure the most important configurations
- Improve: Show ⌛ instead of the flame icon when it is about to expire
- Improve: FAQ is now in the app rather than opening in the browser
- Improve: Videos can now be paused
- Improve: Lock to record hands-free
- Fix: Many smaller issues

## 0.1.8

- Improve: Typos and grammar issues thanks to @AlbertUnruh
- Fix: App becomes unresponsive when clicking notifications.

## 0.1.7

- Improve: Show input indicator in the chat overview as well
- Improve: Username change error handling
- Fix: Phantom push notification
- Fix: Start in chat, if configured
- Fix: Smaller UI fixes

## 0.1.5

- Fix: Reupload of media files was not working properly
- Fix: Chats were sometimes ordered wrongly
- Fix: Typing indicator was not always shown
- Fix: Multiple smaller issues

## 0.1.4

- New: Typing and chat open indicator
- New: Screen lock for twonly (Can be enabled in the settings.)
- Improve: Visual indication when connected to the server
- Improve: Several minor issues with the user interface
- Fix: Poor audio quality and edge distortions in videos sent from Android

## 0.1.3

- New: Video stabilization
- New: Crop or rotate images before sharing them.
- New: Clicking on “Text Notifications” will now open the chat directly (Android only)
- New: Developer settings to reduce flames
- Improve: Improved troubleshooting for issues with push notifications
- Improve: A message appears if someone has deleted their account.
- Improve: Make the verification badge more visible.
- Fix: Flash not activated when starting a video recording
- Fix: Problem sending media when a recipient has deleted their account.
- Fix: Receive push notifications without receiving an in-app message (Android)
- Fix: Issue with sending GIFs from Memories
- Fix: Incorrect processing of messages that have already been fetched from the server causes the UI to freeze

## 0.1.1

- New: Groups can now collect flames as well
- New: Background execution to pre-load messages
- New: Adds a link if the image contains a QR code
- Improve: Video compression with progress updates
- Improve: Show message "Flames restored"
- Improve: Show toast message if user was added via QR
- Fix: Media file appears as a white square and is not listed.
- Fix: Issue with media files required to be reuploaded
- Fix: Problem during contact requests
- Fix: Problem with deleting a contact
- Fix: Problem with restoring from backup
- Fix: Issue with the log file

## 0.0.96

- New: Show link in chat if the saved media file contains one
- Improve: Verification badge for groups
- Improve: Huge reduction in app size
- Fix: Crash on older devices when compressing a video
- Fix: Problem with decrypting messages fixed

## 0.0.93

- New: Verification checkmark for friends
- Fix: Added contacts in contact sharing that were not clickable.
- Fix: Open chat after the image expires in case a draft message exists
- Fix: Restore flames as a plus user
- Fix: Route not found when sharing image
- Fix: Increase recent limit in emoji keyboard
- Fix: Increase show time of the focus indication
- Fix: Quoted text message not shown properly
- Fix: Push notification in groups when someone saves an image
- Fix: Dark mode in diagnostics view

## 0.0.92

- New: The option to share contacts
- New: Option to zoom in received images / videos
- Fix: Issue with "reuploaded requested" not working
- Fix: Race condition while writing to the log file

## 0.0.91

- Fix: Link preview on iOS
- Fix: Sharing images from other apps on iOS

## 0.0.90

- Fix: Issue that media files were not reuploaded
- Fix: iOS zooming issue when switching between .5 and x1
- Fix: Biometric auth bypass when opening a twonly/reopen send image
- Fix: That media files could not be downloaded in case the contact deleted his account
- Fix: Database issue in case twonly is opened multiple times
- Fix: Typos in translation

## 0.0.87

- New: Link preview to shared links
- New: Option to manual focus in the camera
- New: Support to switch between front and back cameras during video recording
- New: Basic face filters
- Improve: Image editor, like emojis or text under a drawing can be moved
- Improve: Speed after taking a picture
- Fix: Issue with emojis disappearing in the image editor

## 0.0.86

- New: Allows to reopen send images (if send without time limit or enabled auth)
- New: Support for front camera zoom
- Fix: Several bug fixes

## 0.0.83

- Improve: View of the diagnostic log
- Fix: Several bug fixes

## 0.0.82

- New: An option in the settings to automatically save all sent images
- New: Hides duplicate images in the memory
- Improve: Several other minor improvements
- Fix: A bug where messages were not being received

## 0.0.81

- Fix: The issue where black/blank images were sometimes received
- Fix: An issue in the image editor

## 0.0.80

- New: Share images/videos directly from other applications
- New: More customization options in the appearance settings
- Improve: UI for changing the display time of images
- Improve: Several minor UI improvements
- Fix: Several bug fixes

## 0.0.74

- Improve: Uploading speed
- Fix: Issue with ffmpeg for android

## 0.0.73

- New: Integrated QR code scanner in the main camera
- New: Profile share page
- New: Workflow for checking the security number
- Improve: User interface for creating voice messages

## 0.0.69

- New: Option to export and import memories
- New: iOS support for ultra-wide-angle camera
- New: Support Android Monochrome Icon
- Fix: Multiple layout issues fixed
- Fix: Multiple bug fixes

## 0.0.67

- New: Crash reports (optional). Please consider enabling this under Settings > Help > “Share errors and crashes with us.”
- Fix: Bug when saving images to the gallery
- Fix: Multiple layout issues fixed
- Fix: Multiple bug fixes

## 0.0.62

- New: Support for groups with multiple administrators
- New: Edit and delete messages
- New: Create images using volume buttons
- New: Removing audio after recording is possible
- New: Edited image is now embedded into the video
- New: Video max length increased to 60 seconds
- New: Context menu and other UI enhancements
- New: Client-to-client protocol migrated to Protocol Buffers (Protobuf)
- New: Database identifiers converted to UUIDs and the database schema completely redesigned
- Improve: Emoji picker
- Improve: Switched to FFmpeg for improved video compression
- Improve: Reliability of client-to-client messaging
- Fix: Multiple bug fixes

## 0.0.61

- New: Image editor when changing colors
- New: Dependency and Flutter upgrade
- Fix: Message decryption error
- Fix: Issue with user deletion
- Fix: Issue with flame counter sync

## 0.0.60

- New: Display your own avatar in the title bar of the chat list.
- New: Created a default avatar image in case none was set.
- New: Flutter SDK and dependencies upgraded.
- Improve: Logging to debug the 'Tap to load' issue.
- Improve: UI handling when requesting microphone access for the first time.
- Fix: Multiple bug fixes.

## 0.0.59

- New: Location Filter are now stored as WebP instead of PNG
- Fix: Media download error
- Fix: Issue with video recording

## 0.0.58

- New: iOS gestures to close images
- New: Onboarding screens updated and registration view simplified
- New: The sender is displayed in the top right corner when a media file is opened
- New: Images are now stored as WebP to save storage
- New: Button to report users
- Improve: Chat messages view, including better citation view and display times
- Fix: Multiple bug fixes
