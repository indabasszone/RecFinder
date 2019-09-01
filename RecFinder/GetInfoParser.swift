//
//  GetInfoParser.swift
//  RecFinder
//
//  Created by Bert Love on 8/20/19.
//  Copyright © 2019 Bert Love. All rights reserved.
//

import UIKit

//Class to get the info for individual artists
//For ViewController: finds which similar artists are under the listener limit
//For TagsViewController: finds which similar artists have one of the desired tags
class GetInfoParser: NSObject, XMLParserDelegate {
    
    //MARK: Properties
    /*artists is the similarArtists array passed in from ViewController
      mode determines what attribute we're looking for: listener count or tags
      limit is the listener limit passed in from ViewController for obscure mode
      tags is the array of tags passed in from TagsViewController for tags mode
      matchingArtists stores all of the artists that fit the specified criteria
      matchingAttributes stores either the corresponding listener count or matching tag
      currentTag and currentArtist used to store values between XMLParser method
      numArtists used to cap the number of artists returned at 10
      reachedTags tracks whether or not we've reached the "tags" tag when parsing the XML
    */
    private var artists: [String]
    private var mode: String
    private var limit: Int
    private var tags: [String]
    private var matchingArtists: [String]
    private var matchingAttributes: [String]
    private var currentTag: String
    private var currentArtist: String
    private var numArtists: Int
    private var reachedTags: Bool
    
    //Initializes all of the instance variables for the ArtistParser
    init?(artists: [String], limit: Int?, mode: String, tags: [String]?) {
        guard !artists.isEmpty else {
            return nil
        }
        
        self.artists = artists
        self.limit = limit ?? 0
        self.tags = tags ?? []
        self.matchingArtists = [String]()
        self.matchingAttributes = [String]()
        self.currentTag = ""
        self.currentArtist = ""
        self.numArtists = 0
        self.mode = mode
        self.reachedTags = false
    }
    
    //MARK: Private Functions
    //Function to find which similarArtists meet the specified criteria
    func getMatchingArtists() -> [String]? {
        //Goes through every artist in the similarArtists array
        for artist in artists {
            //last.fm API calls require that spaces be replaced with '+', "&" be replaced with "%26"
            var artistFix = artist.replacingOccurrences(of: " ", with: "+")
            artistFix = artistFix.replacingOccurrences(of: "&", with: "%26")
            currentArtist = artist
            
            //For some reason I made the urlString separately here
            let urlString = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=d77c476954f65dcebba5122c6a43dafa&artist=" + artistFix
            
            guard let lfmURL = URL(string: urlString) else {
                //print(urlString)
                //print("Error with URL")
                continue
            }
            
            guard let newParser = XMLParser(contentsOf: lfmURL) else {
                print("Error creating parser")
                continue
            }
            
            newParser.delegate = self
            newParser.parse()
            
            //Stops the loop once it gets 10 artists
            if numArtists >= 10 {
                break
            }
        }
        
        //Returns the list of matching artists
        return self.matchingArtists
    }
    
    //Returns the corresponding list of matching attributes for all matching artists
    func getMatchingAttribute() -> [String] {
        return self.matchingAttributes
    }
    
    //MARK: Parser delegate functions
    //Function called when the parser encounters an XML start tag
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        //Checks to see if an error occurred with the API; aborts parsing if so
        if elementName == "lfm" {
            if attributeDict["status"] == "failed" {
                parser.abortParsing()
            }
        //For tags mode, need to know if we've reached the tags section
        } else if elementName == "tags" {
            reachedTags = true
        }
        
        currentTag = elementName
    }
    
    //Handles the data inside of a tag
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        //For obscure mode: When it finds the listener tag, it checks if the count is less than the limit
        //If so, it appends the data to the arrays and increments numArtists
        //Only info we want is listener count so it terminates the parser
        if mode == "obscure" {
            if currentTag == "listeners" {
                let listeners = Int(string) ?? 0
                
                if listeners <= limit {
                    matchingArtists.append(currentArtist)
                    matchingAttributes.append(string)
                    numArtists += 1
                }
                parser.abortParsing()
            }
            
        //For tags mode: the tag name also falls under a "name" tag (like the artist name),
        //so we need to make sure we've reached the tags section before looking at the value.
        //If it finds a matching tag, it appends the data to the arrays and terminates the parser
        } else {
            if currentTag == "name" && reachedTags {
                if tags.contains(string) {
                    matchingArtists.append(currentArtist)
                    matchingAttributes.append(string)
                    numArtists += 1
                    parser.abortParsing()
                }
            }
        }
    }
    
}
