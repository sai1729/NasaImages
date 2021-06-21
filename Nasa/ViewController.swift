//
//  ViewController.swift
//  Nasa
//
//  Created by Dondeti, Sai Krishna on 21/06/21.
//
//https://api.nasa.gov/planetary/apod?api_key=tjC8dmVZAHAL2oe9rHrQLDTGUOpBskyk3Wokjy9m
import UIKit
var count = 0
class ViewController: UIViewController {
    
    @IBOutlet weak var nasaImage: UIImageView!
    @IBOutlet weak var titleView: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    override func viewDidLoad() {
        loadDataValues()
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    func loadDataValues() {
        count = count + 1
        if(status == false){
            self.showError(error: "We are not connected to the internet, showing you the last image we have.")
        }
            guard let url = URL(string: "https://api.nasa.gov/planetary/apod?api_key=tjC8dmVZAHAL2oe9rHrQLDTGUOpBskyk3Wokjy9m") else {
                return
            }
            let request = URLRequest(url: url)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let data = data {
                    do {
                        let fileURL = try FileManager.default
                            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                            .appendingPathComponent("example.json")

                        try data.write(to: fileURL)
                    } catch {
                        print(error)
                    }
                }
            }.resume()
        getValuesfromJson()

    }
    
    func getValuesfromJson() {
        do {
            let fileURL = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("example.json")
            
            let data = try Data(contentsOf: fileURL)
            guard let responseDictionary = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else { return }
            guard let imageUrl = responseDictionary["hdurl"] else{ return}
            guard let titleText = responseDictionary["title"] else{ return}
            guard let descriptionText = responseDictionary["explanation"] else{ return}
            
            do{
                let fileURLData = try FileManager.default
                    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    .appendingPathComponent((imageUrl as AnyObject).lastPathComponent, isDirectory: true)
                        
                let dataValue = try Data(contentsOf: fileURLData)
                DispatchQueue.main.async() { [weak self] in
                    self?.nasaImage.image = UIImage(data: dataValue)
                }
            }
            catch{
                print(error)
                downloadImage(from: URL(string: imageUrl as! String)!)
            }
            self.titleView.text = titleText as? String
            self.descriptionView.text = descriptionText as? String
        } catch {
            print(error)
            if(count == 3){
                self.loadDataValues()
            }
        }
    }
    
    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            do {
                let fileURL = try FileManager.default
                    .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    .appendingPathComponent(response?.suggestedFilename ?? url.lastPathComponent)
                
                try data.write(to: fileURL)
            } catch {
                print(error)
            }
            
            print("Download Finished")
            // always update the UI from the main thread
            DispatchQueue.main.async() { [weak self] in
                self?.nasaImage.image = UIImage(data: data)
            }
        }
    }
    
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
        
    func createDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let dataPath = docURL.appendingPathComponent("MyFolder")
        if !FileManager.default.fileExists(atPath: dataPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func showError(error: String) {
        DispatchQueue.main.async {
            let ac = UIAlertController(title: "Loading error", message: error, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
    }
}
