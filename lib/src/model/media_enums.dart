// Persisted enum names must stay compatible with the Rust database.

enum MediaType {
  image,
  video,
  gif,
  audio,
}

enum CloudState {
  none,
  pending,
  uploaded,
}

enum UploadState {
  // Image/Video was taken. A database entry was created to track it...
  initialized,
  // Image was stored but not send
  storedOnly,
  // At this point the user is finished with editing, and the media file can be uploaded
  preprocessing,
  uploading,
  backgroundUploadTaskStarted,
  uploaded,

  uploadLimitReached,

  // File is to big to be uploaded
  fileLimitReached,
  // readyToUpload,
  // uploadTaskStarted,
  // receiverNotified,
}

enum DownloadState {
  pending,
  downloading,
  downloaded,
  ready,
  reuploadRequested,
}
