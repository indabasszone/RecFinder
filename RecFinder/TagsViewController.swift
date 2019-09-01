//
//  TagsViewController.swift
//  RecFinder
//
//  Created by Bert Love on 8/31/19.
//  Copyright © 2019 Bert Love. All rights reserved.
//

import UIKit

class TagsViewController: UIViewController, XMLParserDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    //MARK: Properties
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var artistsTextField: UITextField!
    @IBOutlet weak var tagsTextField: UITextField!
    @IBOutlet weak var tagsListLabel: UILabel!
    @IBOutlet weak var findRecsButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    /* All of the variables used in parsing.
    - similarArtists stores all the similar artists from GetSimilarParser
    - matchingArtists and matchingTags store the results from GetInfoParser
    - errorMsg is used the API call fails in GetSimilarParser
    */
    var similarArtists = [String]()
    var matchingArtists = [String]()
    var matchingTags = [String]()
    var errorMsg: String = ""
    
    //The artist to search and list of tags to match provided by the user
    var artist: String = "Artist not yet provided"
    var tags = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        //Assigns delegates, hides the table view until it has data,
        //disables the button until the user enters an artist and limit
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isHidden = true
        findRecsButton.isEnabled = false
        artistsTextField.delegate = self
        tagsTextField.delegate = self
    }
    
    //MARK: Actions
    @IBAction func findRecsBtnPressed(_ sender: UIButton) {
        //Clears all results from previous searches and calls parseXML to get new data
        similarArtists.removeAll()
        matchingArtists.removeAll()
        matchingTags.removeAll()
        
        //Creates a GetSimilarParser to get an array of all similar artists
        let getSimilarParser = GetSimilarParser(artist: artist)
        
        //Calls findSimilarArtists() on the parser, which returns a bool indicating success or failure
        //If the call was successful, it passes the array of similarArtists to a GetInfoParser,
        //which will return an array of artists with matching tags, as well as
        //an array of the tags each artists matched with
        if getSimilarParser!.findSimilarArtists() {
            similarArtists = (getSimilarParser?.getSimilarArtists())!
            
            let getInfoParser = GetInfoParser(artists: similarArtists, limit: nil, mode: "tags", tags: tags)
            matchingArtists = (getInfoParser?.getMatchingArtists() ?? [])
            matchingTags = (getInfoParser?.getMatchingAttribute() ?? [])
            
            //In case no artists are found
            if (matchingArtists.count == 0) {
                matchingArtists.append("No artists found!")
            }
            
            if (matchingTags.count == 0) {
                matchingTags.append("")
            }
            
        //If the call failed, it gets the error message and adds it to the table
        } else {
            errorMsg = (getSimilarParser?.getErrorMsg())!
            matchingArtists.append("An error occurred:")
            matchingArtists.append(errorMsg)
            matchingTags.append("")
            matchingTags.append("")
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
        return matchingArtists.count + 1
    }
    
    //Function called when updating the values in the table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        
        //For the first row, adds headers and bolds the text
        if indexPath.row == 0 {
            cell.textLabel?.text = "Artist"
            cell.detailTextLabel?.text = "Matching Tag"
            
            cell.textLabel?.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
            cell.detailTextLabel?.font = UIFont(name:"HelveticaNeue-Bold", size: 16.0)
            
        //Subsequently adds cells for all obscure artists found
        //Artist name on the left, matching tag on the right (detail)
        } else {
            cell.textLabel?.text = matchingArtists[indexPath.row-1]
            cell.detailTextLabel?.text = matchingTags[indexPath.row-1]
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
        if textField == artistsTextField {
            artist = textField.text!
        
        //If its the text field for the tags, it adds the tag to the array of tags
        //If the tag is already in the array it removes it
        } else if textField == tagsTextField {
            let tag = textField.text!
            
            if tags.contains(tag) {
                let index = tags.firstIndex(of: tag)!
                tags.remove(at: index)
                tagsListLabel.text = tagsListLabel.text!.replacingOccurrences(of: tag + ", ", with: "")
                tagsListLabel.text = tagsListLabel.text!.replacingOccurrences(of: tag, with: "")
            } else {
                tags.append(tag)
                if (tags.count > 1) {
                    tagsListLabel.text! += ", "
                }
                tagsListLabel.text! += tag
            }
        }
        
        //If the user has entered a valid list of tags and artist name, button is enabled
        //Will disable the button if the user removes all the tags
        if (tags.count > 0 && !(artist.isEmpty)) {
            findRecsButton.isEnabled = true
            findRecsButton.setTitle("Find Recommendations", for: .normal)
        } else {
            findRecsButton.isEnabled = false
            findRecsButton.setTitle("Waiting for Inputs...", for: .normal)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
