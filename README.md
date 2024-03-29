# RecFinder
RecFinder is an iOS app designed to help users find musical artists similar to other artists based on specified criteria. The app uses the Last.fm API to find the similar artists, then uses the API to get each artist's info to see if they fit the criteria. The list of recommendations can be filtered based either on listener count (to find artists at a certain level of obscurity) or tags (to find artists with a desired characteristic). The app lists the recommendations in a table, where the user can click on an artist to visit their Last.fm profile. The app is written in Swift 5 for iOS 13, and also handles XML returned from the API.

The app is not currently on the app store, but you can run it by downloading the project, opening it in XCode, and running it on a simulator or on a connected device (as long as it is running iOS 13). The actual XCode file is RecFinder.xcodeproj; for some reason it uploaded as a folder, but it'll download as a project file.

![](recfinder.gif)
