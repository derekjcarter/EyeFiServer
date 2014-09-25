EyeFi Server
===

This project is used to implement a server used for Eye-Fi SD cards to contain photos.  This example code is used in an iOS app, built for iOS7 but iOS8 compatible.

1. Currently, you'll need to find your own Eye-Fi upload key.  Under Mac OS, you can find that key at __~/Library/Eye-Fi/Settings.xml__.  
2. Plenty of optimizations regarding the photo file.  These photos are typically large so creating thumbnails of the original photos to display would be recommended.


### Acknowledgments
1. [sceye-fi](https://code.google.com/p/sceye-fi/) - Java project that added very detailed documentation of the upload protocol.
2. [PhotoPad](https://github.com/Ignigena/PhotoPad) - The original project which sparked my interest in Eye-Fi communication between a camera and an iOS app.
