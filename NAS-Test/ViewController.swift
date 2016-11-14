//
//  ViewController.swift
//  NAS-Test
//
//  Created by Kayoti on 12/11/16.
//  Copyright © 2016 NAS Media. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Alamofire
import SwiftyJSON
import AVFoundation


class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate {
    
    
    var imagePicker = UIImagePickerController()
    
    var location: Location? {
        didSet {
            sendLocation.setTitle(location.flatMap({ $0.title }) ?? "No location selected", for: .normal)
           // locationTxt.text = location.flatMap({ $0.title }) ?? "No location selected"
        }
    }
    
    
    @IBOutlet weak var imagePlaceholder: UIImageView!
    @IBOutlet weak var name: HoshiTextField!
    @IBOutlet weak var email: HoshiTextField!
    @IBOutlet weak var password: HoshiTextField!
    @IBOutlet weak var chooseFavMovie: UIButton!
    @IBOutlet weak var subscribe: UIButton!
    @IBOutlet weak var sendLocation: UIButton!
    @IBOutlet weak var recode: UIButton!
    @IBOutlet weak var recLbl: UILabel!
    @IBOutlet weak var submit: UIButton!
    
    var counter1:Int = 0
    var counter2:Int = 0
    var subscribeStatus = 0
    
    var audioRecorder:AVAudioRecorder?
    var audioPlayer:AVAudioPlayer?
    
    
    @IBAction func imageAction(_ sender: Any) {
        pickPhoto(sender: sender as AnyObject)
    }
    @IBAction func chooseFavAction(_ sender: Any) {
    }

    @IBAction func subscribeAction(_ sender: Any) {
        counter1 += 1
        if counter1 == 1 {
            subscribe.setImage(UIImage(named : "checked"), for: UIControlState.normal)
            subscribeStatus = 0
        }
        
        if counter1 == 2 {
            subscribe.setImage(UIImage(named : "unchecked"), for: UIControlState.normal)
            subscribeStatus = 1
            counter1 = 0
        }
        
    }
    
    @IBAction func sendLocationAction(_ sender: Any) {
    }

    @IBAction func submit(_ sender: Any) {
        validate()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(name: "Avenir-Medium", size: 17)!]
        
        let coordinates = CLLocationCoordinate2D(latitude: 20.593, longitude: 78.96)
        location = Location(name: "Send Location", location: nil,
                            placemark: MKPlacemark(coordinate: coordinates, addressDictionary: [:]))
        
        imagePlaceholder.layer.cornerRadius = 65
        
        
        
        // Get the document directory. If fails, just skip the rest of the code
        guard let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            
            let alertMessage = UIAlertController(title: "Error", message: "Failed to get the document directory for recording the audio. Please try again later.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
            
            return
        }
        
        // Set the default audio file
        let audioFileURL = directoryURL.appendingPathComponent("MyAudioMemo.m4a")
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
            
            // Define the recorder setting
            let recorderSetting: [String: AnyObject] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
                AVSampleRateKey: 44100.0 as AnyObject,
                AVNumberOfChannelsKey: 2 as AnyObject,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue as AnyObject
            ]
            
            // Initiate and prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            
        } catch {
            print(error)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //------------------------------------------------
    //MARK: Picker photo
    //------------------------------------------------
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let img = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagePlaceholder.image = img
            imagePlaceholder.clipsToBounds = true
        } else{
            print("Something went wrong")
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancel picking image")
        
        dismiss(animated: true, completion: nil)
        
    }
    
    func pickPhoto(sender: AnyObject) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showPhotoMenu(sender: sender)
        } else {
            choosePhotoFromLibrary()
        }
    }
    
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showPhotoMenu(sender: AnyObject) {
        
        let alertController = UIAlertController(title: nil, message: nil,preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let takePhotoAction = UIAlertAction(title: "Take Photo",style: .default, handler: { _ in self.takePhotoWithCamera()})
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title:"Choose From Library", style: .default, handler:{ _ in self.choosePhotoFromLibrary()})
        
        alertController.addAction(chooseFromLibraryAction)
        //for ipad action sheet
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender as? UIView
            popoverController.sourceRect = sender.bounds
        }
        
        present(alertController, animated: true, completion: nil)
    }
    @IBAction func recode(_ sender: Any) {
        counter2 += 1
        if counter2 == 1 {
            recLbl.text = "Recording.."
        }
        if counter2 == 2 {
            recLbl.text = "Recorded"
            counter2 = 0
        }
        
        if counter2 == 0 {
            recLbl.text = "Recorde"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LocationPicker" {
            let locationPicker = segue.destination as! LocationPickerViewController
            locationPicker.location = location
            locationPicker.showCurrentLocationButton = true
            locationPicker.useCurrentLocationAsHint = true
            locationPicker.showCurrentLocationInitially = true
            
            locationPicker.completion = { self.location = $0 }
        }
    }
    
    //Funcation to call alert
    func callAlert(_title: String, _msg:String) {
        let alert = UIAlertController(title: _title, message: _msg, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil);
    }
    
    func showTextHUD(msg:String){
        let hud: MBProgressHUD = MBProgressHUD.showAdded(to: self.view!, animated: true)
        // Set the custom view mode to show any view.
        hud.mode = .text
        hud.label.text = msg
        // Move to bottm center.
       // hud.offset = CGPointMake(0.0, MBProgressMaxOffset)
        hud.hide(animated: true, afterDelay: 1.0)
    }
    
    func isPwdLenth(password: String) -> Bool {
        if password.characters.count <= 6 {
            return true
        }
        else{
            return false
        }
    }
    func validate() {
        
        
        
        if imagePlaceholder.image == UIImage(named : "img_placeholder") {
            showTextHUD(msg: "Set Image")
        }
        else {
            if name.text == "" {
                showTextHUD(msg: "Enter Name")
            }
            else {
                if email.text == "" {
                    showTextHUD(msg: "Enter Email")
                }
                else {
                    if password.text == "" {
                        showTextHUD(msg: "Enter Password")
                    }
                    else if email.text != "" || password.text != "" {
                        print("all are full")
                        if (email.text?.isEmail)! {
                            print("email ok")
                            if isPwdLenth(password: password.text!) {
                                showTextHUD(msg: "password morethan 6 character")
                            }
                            else {
                                print("passworOK")
                                
                            }
                        }
                        else {
                            showTextHUD(msg: "Enter correct email")
                        }
                    }
                }
                
            }
        }
        

    }
    
    
    func recordAudio() {
        // Stop the audio player before recording
        if let player = audioPlayer {
            if player.isPlaying {
                player.stop()
            }
        }
        
        if let recorder = audioRecorder {
            if !recorder.isRecording {
                let audioSession = AVAudioSession.sharedInstance()
                
                do {
                    try audioSession.setActive(true)
                    
                    // Start recording
                    recorder.record()
                } catch {
                    print(error)
                }
                
            } else {
                // Pause recording
                recorder.pause()

            }
        }
        
    }

    
    func callAPI() {
        let image =  UIImage(named: "Call")!
        let defaults = UserDefaults.standard
        let _lat = defaults.string(forKey: "latitude")
        let _long = defaults.string(forKey: "longitude")
    
        
            let parameters = [
                "name": name.text!,
                "email": email.text!,
                "password": password.text!,
                "subscribe": subscribeStatus,
                "movie": "Starwars",
                "file" : "base64String",
                "audio": "2.m4a",
                "birth_day": "1995-01-26",
                "location_lat": _lat!,
                "location_lng": _long!
            ] as [String : Any]

        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imageData = UIImageJPEGRepresentation(image, 1) {
                multipartFormData.append(imageData, withName: "file", fileName: "file.png", mimeType: "image/png")
            }
            
            for (key, value) in parameters {
                multipartFormData.append(((value as AnyObject).data(using: .utf8))!, withName: key)
            }}, to: "http://rt.sz4h.com/index.php", method: .post,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                           // debugPrint(response)
                            if let json = response.result.value {
                                print("JSON: \(json)")
                            }
                        }
                    case .failure(let encodingError):
                        print(encodingError)
                    }
               })
         }

}


extension String {
    
    //Validate Email
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }
}

