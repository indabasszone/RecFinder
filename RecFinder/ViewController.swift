//
//  ViewController.swift
//  RecFinder
//
//  Created by Bert Love on 8/20/19.
//  Copyright © 2019 Bert Love. All rights reserved.
//

import UIKit

class ViewController: UIViewController, XMLParserDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var findRecsButton: UIButton!
    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var listenersTextField: UITextField!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var limitLabel: UILabel!
    
    /* All of the variables used in parsing.
     - similarArtists stores all the similar artists from GetSimilarParser
     - obscureArtists and listenerCounts store the results from GetInfoParser
     - errorMsg is used the API call fails in GetSimilarParser
     */
    var similarArtists = [String]()
    var obscureArtists = [String]()
    var listenerCounts = [String]()
    var errorMsg: String = ""
    
    //The artist to search and listener limit provided by the user
    var artist: String = "Artist not yet provided"
    var limit: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Assigns delegates, hides the table view until it has data,
        //disables the button until the user enters an artist and limit
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        findRecsButton.isEnabled = false
        artistTextField.delegate = self
        listenersTextField.delegate = self
        tableView.allowsSelection = true
        tableView.isScrollEnabled = true
    }

    //MARK: Actions
    //Function called when the "find recommendations" button is pressed
    @IBAction func findArtistBtnPressed(_ sender: UIButton) {
        //Clears all results from previous searches and calls parseXML to get new data
        similarArtists.removeAll()
        obscureArtists.removeAll()
        listenerCounts.removeAll()
        
        let getSimilarParser = GetSimilarParser(artist: artist)
        
        //If the call was successful, it passes the array of similarArtists to an ArtistParser,
        //which will return an array of artists with listener counts under the limit, as well as
        //an array of all their corresponding listener counts
        if getSimilarParser!.findSimilarArtists() {
            similarArtists = (getSimilarParser?.getSimilarArtists())!
            
            let getInfoParser = GetInfoParser(artists: similarArtists, limit: limit, mode: "obscure", tags: nil)
            obscureArtists = (getInfoParser?.getMatchingArtists() ?? [])
            listenerCounts = (getInfoParser?.getMatchingAttribute() ?? [])
            
            //In case no artists are found
            if (obscureArtists.count == 0) {
                obscureArtists.append("No artists found!")
            }
            
            if (listenerCounts.count == 0) {
                listenerCounts.append("")
            }
            
        //If the call failed, it gets the error message and adds it to the table
        } else {
            errorMsg = (getSimilarParser?.getErrorMsg())!
            obscureArtists.append("An error occurred:")
            obscureArtists.append(errorMsg)
            listenerCounts.append("")
            listenerCounts.append("")
        }
        
        //Now that we have data, it updates and reveals the table
        tableView.reloadData()
        tableView.isHidden = false
    }
    
    //MARK: Table View Data Source
    //Only one section in the table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //Number of rows is the number of artist found + a row for the header
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return obscureArtists.count + 1
    }
    
    //Function called when updating the values in the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        
        //For the first row, adds headers and bolds the text
        if indexPath.row == 0 {
            cell.textLabel?.text = "Artist"
            cell.detailTextLabel?.text = "Listeners"
            
            cell.textLabel?.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
            cell.detailTextLabel?.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
            
        //Subsequently adds cells for all obscure artists found
        //Artist name on the left, listener count on the right (detail)
        } else {
            cell.textLabel?.text = obscureArtists[indexPath.row-1]
            cell.detailTextLabel?.text = listenerCounts[indexPath.row-1]
        }
        
        return cell
    }
    
    //Opens the artist's last.fm page in browser if selected
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath)
        let artistName = currentCell?.textLabel?.text
        
        var artistFix = artistName?.replacingOccurrences(of: " ", with: "+")
        artistFix = artistFix?.replacingOccurrences(of: "&", with: "%26")
        
        let urlString = "https://www.last.fm/music/" + (artistFix ?? "")
        UIApplication.shared.open(URL(string: urlString)!)
    }
    
    //MARK: UITextFieldDelegate
    //Hides the keyboard when the user is done editing a text field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //Function called after user enters text into a text field
    func textFieldDidEndEditing(_ textField: UITextField) {
        //If its the text field for the artist name, it updates that field
        if textField == artistTextField {
            artist = textField.text!
        
        //If its the text field for the listener count it updates that
        //If the user does not provide a valid int it defaults to -1
        } else if textField == listenersTextField {
            limit = Int(textField.text!) ?? -1
        }
        
        //If the user has entered a valid limit and artist name, button is enabled
        if (limit > 0 && !(artist.isEmpty)) {
            findRecsButton.isEnabled = true
            findRecsButton.setTitle("Find Recommendations", for: .normal)
        }
    }
    
}

