//
//  ProfileViewController.swift
//  LogInFB
//
//  Created by Deniz Adil on 16.11.20.
//

import UIKit
import Kingfisher
import CoreServices

enum ProfileViewTableData {
    case basicInfo
    case aboutMe
    case stats
    case myMoments
    
    var cellIdentifier: String {
        switch self {
        case .basicInfo:
            return "basicInfoCell"
        case .aboutMe:
            return "aboutMeCell"
        case .stats:
            return "statsCell"
        case .myMoments:
            return ""
        }
    }
    var cellHeight: CGFloat {
        switch self {
        case .basicInfo:
            return 95
        case .aboutMe:
            return 95
        case .stats:
            return 95
        case .myMoments:
            return 95
        }
    }
}


class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private let tableData: [ProfileViewTableData] = [.basicInfo, .aboutMe, .stats]
    
    private var pickedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        title = "You"
        setupNewPostButton()
    }
    private func setupNewPostButton() {
        let button = UIButton()
        button.setImage(UIImage(named: "NoteIcon"), for: .normal)
        button.setTitle(nil, for: .normal)
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: button)]
       // navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }
    private func setupTableView() {
        tableView.register(UINib(nibName: "BasicInfoTableViewCell", bundle: nil), forCellReuseIdentifier: ProfileViewTableData.basicInfo.cellIdentifier)
        tableView.register(UINib(nibName: "AboutMeTableViewCell", bundle: nil), forCellReuseIdentifier: ProfileViewTableData.aboutMe.cellIdentifier)
        tableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: ProfileViewTableData.stats.cellIdentifier)
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor(hex: "F1F1F1")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets.zero
    }
    private func openEditImageSheet() {
        let actionSheet = UIAlertController(title: "Edit image", message: "Plaese pick an image", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) { _ in
            self.openImagePicker(sourceType: .camera)
        }
        let library = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.openImagePicker(sourceType: .photoLibrary)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(camera)
        actionSheet.addAction(library)
        actionSheet.addAction(cancel)
        
        present(actionSheet, animated: true, completion: nil)
    }
    private func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = false
        if sourceType == .camera {
            imagePicker.cameraDevice = .front
        }
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    private func uploadImage(image: UIImage) {
        guard var user = DataStore.shared.localUser, let userId = user.id else {
            return
        }
        DataStore.shared.uploadImage(image: image, userId: userId) { (url, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let url = url {
                user.imageUrl = url.absoluteString
                DataStore.shared.setUserData(user: user) { (_, _) in }
            }
        }
    }
}

extension ProfileViewController: BasicinfoCellDelegate {
    func didClickOnEditImage() {
        openEditImageSheet()
    }
    
    func didTapOnUserImage(user: User?, image: UIImage?) {
        //To open full screen image for user...
    }
}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            self.pickedImage = image
            self.uploadImage(image: image)
            self.tableView.reloadRows(at: [IndexPath(item: 0, section: 0)], with: .automatic)
        }
    }
}

extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return tableData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let localUser = DataStore.shared.localUser else {
            return UITableViewCell()
        }
        let data = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: data.cellIdentifier)
        return getCellFor(data: data, user: localUser, cell: cell)
    }
    private func getCellFor(data: ProfileViewTableData, user: User, cell: UITableViewCell?) -> UITableViewCell {
        switch data {
        case .basicInfo:
            guard let basicCell = cell as? BasicInfoTableViewCell else {
                return UITableViewCell()
            }
            basicCell.profileImage.image = pickedImage
            basicCell.user = user
            basicCell.lblName.text = user.fullName
            basicCell.lblOtherInfo.text = (user.gender ?? "") + ", " + (user.location ?? "") //Dokolku propertito e nil ke ja zeme desnata vrednost odnosno “defaultValue” (variable ?? defaultValue)
            if let imageUrl = user.imageUrl {
                basicCell.profileImage.kf.setImage(with: URL(string: imageUrl), placeholder: UIImage(named: "userPlaceholder"))
            }
            basicCell.selectionStyle = .none
            basicCell.delegate = self
            return basicCell
        case .aboutMe:
            guard let aboutCell = cell as? AboutMeTableViewCell else {
                return UITableViewCell()
            }
            aboutCell.lblAboutMe.text = user.aboutMe
            aboutCell.selectionStyle = .none
            return aboutCell
        case .stats:
            guard let statsCell = cell as? StatsTableViewCell else {
                return UITableViewCell()
            }
            statsCell.lblMomentsNumbers.text = "\(user.moments ?? 0)"
            statsCell.lblFollowersNumbers.text = "\(user.followers ?? 0)"
            statsCell.lblFollowingNumbers.text = "\(user.following ?? 0)"
            
            statsCell.selectionStyle = .none
            return statsCell
        case .myMoments:
            return UITableViewCell()
        }
    }
}
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
}
