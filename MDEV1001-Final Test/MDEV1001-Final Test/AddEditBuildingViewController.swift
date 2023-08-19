import UIKit
import Firebase

class AddEditBuildingViewController: UIViewController {
    
    // UI References
    @IBOutlet weak var AddEditTitleLabel: UILabel!
    @IBOutlet weak var UpdateButton: UIButton!
    
    // Building Fields
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var typeTextField: UITextField!
    @IBOutlet weak var dateBuiltTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var countryTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var architectsTextField: UITextField!
    @IBOutlet weak var costTextField: UITextField!
    @IBOutlet weak var websiteTextField: UITextField!
    @IBOutlet weak var imageURLTextField: UITextField!
    
    var building: Building?
    var buildingViewController: FirestoreCRUDViewController?
    var buildingUpdateCallback: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let building = building {
            // Editing existing building
            nameTextField.text = building.name
            typeTextField.text = building.type
            dateBuiltTextField.text = building.dateBuilt
            cityTextField.text = building.city
            countryTextField.text = building.country
            descriptionTextView.text = building.description
            architectsTextField.text = building.architects
            costTextField.text = building.cost
            websiteTextField.text = building.website
            imageURLTextField.text = building.imageURL
            
            AddEditTitleLabel.text = "Edit Building"
            UpdateButton.setTitle("Update", for: .normal)
            
            if let imageURL = URL(string: building.imageURL) {
                URLSession.shared.dataTask(with: imageURL) { data, response, error in
                    if let data = data {
                        DispatchQueue.main.async {
                            self.imageView.image = UIImage(data: data)
                        }
                    }
                }.resume()
            }
        } else {
            AddEditTitleLabel.text = "Add Building"
            UpdateButton.setTitle("Add", for: .normal)
        }
    }
    
    @IBAction func CancelButton_Pressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func UpdateButton_Pressed(_ sender: UIButton) {
        guard
            let name = nameTextField.text,
            let type = typeTextField.text,
            let dateBuilt = dateBuiltTextField.text,
            let city = cityTextField.text,
            let country = countryTextField.text,
            let description = descriptionTextView.text,
            let architects = architectsTextField.text,
            let cost = costTextField.text,
            let website = websiteTextField.text,
            let imageURL = imageURLTextField.text else {
            print("Invalid data")
            return
        }
        
        let buildingData = Building(
            name: name,
            type: type,
            dateBuilt: dateBuilt,
            city: city,
            country: country,
            description: description,
            architects: architects,
            cost: cost,
            website: website,
            imageURL: imageURL
        )
        
        let db = Firestore.firestore()
        
        if let building = building {
            // Update existing building
            guard let documentID = building.documentID else {
                print("Document ID not available.")
                return
            }
            
            let buildingRef = db.collection("buildings").document(documentID)
            buildingRef.updateData([
                "name": buildingData.name,
                "type": buildingData.type,
                "dateBuilt": buildingData.dateBuilt,
                "city": buildingData.city,
                "country": buildingData.country,
                "description": buildingData.description,
                "architects": buildingData.architects,
                "cost": buildingData.cost,
                "website": buildingData.website,
                "imageURL": buildingData.imageURL
            ]) { [weak self] error in
                if let error = error {
                    print("Error updating building: \(error)")
                } else {
                    print("Building updated successfully.")
                    self?.dismiss(animated: true) {
                        self?.buildingUpdateCallback?()
                    }
                }
            }
        } else {
            // Add new building
            db.collection("buildings").addDocument(data: [
                "name": buildingData.name,
                "type": buildingData.type,
                "dateBuilt": buildingData.dateBuilt,
                "city": buildingData.city,
                "country": buildingData.country,
                "description": buildingData.description,
                "architects": buildingData.architects,
                "cost": buildingData.cost,
                "website": buildingData.website,
                "imageURL": buildingData.imageURL
            ]) { [weak self] error in
                if let error = error {
                    print("Error adding building: \(error)")
                } else {
                    print("Building added successfully.")
                    self?.dismiss(animated: true) {
                        self?.buildingUpdateCallback?()
                    }
                }
            }
        }
    }
}
