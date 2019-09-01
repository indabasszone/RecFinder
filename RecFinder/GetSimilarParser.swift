//
//  GetSimilarParser.swift
//  RecFinder
//
//  Created by Bert Love on 9/1/19.
//  Copyright © 2019 Bert Love. All rights reserved.
//

import UIKit

//Class to find similar artists for a given artist
class GetSimilarParser: NSObject, XMLParserDelegate {
    // artist is the artist passed in from either ViewController to find similar artists for
    // similarArtists stores all of the similarArtists found when parsing
    // currentTag and currentArtist (self explanatory) are used to store results between XMLParser methods
    // parsingFailed tracks whether or not an error occurred when making the API call
    // errorMsg is the message to be returned if the call fails
    private var artist: String
    private var similarArtists: [String]
    private var currentTag: String
    private var currentArtist: String
    private var parsingFailed: Bool
    private var errorMsg: String
    
    //Initializes all the fields of the parser
    init?(artist: String) {
        self.artist = artist
        self.similarArtists = []
        self.currentTag = ""
        self.currentArtist = ""
        self.parsingFailed = false
        self.errorMsg = ""
    }
    
    //MARK: Private Functions
    //Function to find similar artists, returns success or failure
    func findSimilarArtists() -> Bool {
        //last.fm API calls require that spaces be replaced with '+', "&" be replaced with "%26"
        var artistFix = artist.replacingOccurrences(of: " ", with: "+")
        artistFix = artistFix.replacingOccurrences(of: "&", with: "%26")
        
        //Creates the URL for the API call then creates the parser
        guard let lfmURL = URL(string: "http://ws.audioscrobbler.com/2.0/?method=artist.getsimilar&api_key=d77c476954f65dcebba5122c6a43dafa&limit=500&artist=" + artistFix) else {
            errorMsg = "Error creating URL"
            return false
        }
        
        guard let parser = XMLParser(contentsOf: lfmURL) else {
            errorMsg = "Error creating parser"
            return false
        }
        
        //Sets the parser's delegate to this clas, meaning this is where it looks for the parser methods
        parser.delegate = self
        parser.parse()
        
        return !parsingFailed
    }
    
    //Called when parsing succeeds to get the array of similar artists
    func getSimilarArtists() -> [String] {
        return self.similarArtists
    }
    
    //Called when parsing fails to get the error message
    func getErrorMsg() -> String {
        return self.errorMsg
    }
    
    //MARK: Parser delegate functions
    //Function called when the parser encounters an XML start tag
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        //Checks to see if an error occurred with the API
        if elementName == "lfm" {
            if attributeDict["status"] == "failed" {
                parsingFailed = true
            }
        }
        
        //Updates the current tag
        currentTag = elementName
    }
    
    //Handles the data inside of a tag
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        //For some reason it reads the \n separately from the rest of the string
        //currentTag will not have updated when this happens which is why we need this if statement
        if string != "\n" {
            //The XML parser has a problem with reading apostrophes separately from the artist's name,
            //meaning we have to append the individual characters to the currentArtist string
            //as opposed to just adding the string directly to the similarArtists array
            if currentTag == "name" {
                currentArtist += string
                
            //All artists will have a "match" tag following the artist name
            //This means we have the whole artist name in currentArtist and can append it to the array
            } else if currentTag == "match" {
                similarArtists.append(currentArtist)
                currentArtist = ""
                
            //Gets the error message and stops parsing if an error occurred
            } else if currentTag == "error" {
                errorMsg = string
                parser.abortParsing()
            }
        }
    }
}
