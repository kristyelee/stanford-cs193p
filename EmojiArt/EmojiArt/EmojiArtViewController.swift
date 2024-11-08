//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Kristy Lee on 7/23/19.
//  Copyright © 2019 Kristy Lee. All rights reserved.
//

import UIKit

//
// Useful controller-related utilities for EmojiArt.EmojiInfo
//
extension EmojiArt.EmojiInfo {
    
    ///
    /// Creates a new EmojiArt.EmojiInfo from the given UILabel
    ///
    init?(label: UILabel) {
        // We need attributedText (to know the actual emoji text and size). We need font (to know the emoji size)
        if let attributedText = label.attributedText, let font = attributedText.font {
            // Create the object
            self.x = Int(label.center.x)
            self.y = Int(label.center.y)
            self.size = Int(font.pointSize)
            self.text = attributedText.string
        } else {
            return nil
        }
    }
}

class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    // MARK: - Model
    
    var emojiArt: EmojiArt? {
        get {
            if let url = emojiArtBackgroundImage.url {
                let emojis = emojiArtView.subviews.compactMap{ $0 as? UILabel }.compactMap{ EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            } else {
                return nil
            }
        } set {
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.compactMap { $0 as? UILabel }.forEach { $0.removeFromSuperview() }
            if let url = newValue?.url {
                // Fetch the image from the newly set url
                imageFetcher = ImageFetcher(fetch: url) { (url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let center = CGPoint(x: $0.x, y: $0.y)
                            let emojiSize = CGFloat($0.size)
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: emojiSize)
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: center)
                        }
                    }
                }
            }
        }
    }
    
    var document: EmojiArtDocument?
    
    //update document
    
    
    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
        //look to see if there are any changes before saving
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done) //call update change count when you have updates that you want to save
        }
    }
    
    //open document
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.emojiArt = self.document?.emojiArt
            }
        }
    }
    
    //close document
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        save() //save before closing
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    //set doc to untitled.json, but we remove this because we want the document displayed by the document view browser, not untitled.json
    /*
    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("Untitled.json") {
            document = EmojiArtDocument(fileURL: url)
        }
        
    }*/
    
    
    // MARK: - Storyboard
   
    @IBOutlet weak var dropZone: UIView! {
        didSet {
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = 1.0
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView! {
        didSet {
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true //by default true on ipad, false on iphone, so make true
        }
    }
    var imageFetcher: ImageFetcher!
    
    var emojis = "😀🎁✈️🎱🍎🐶🐝🍮🎼🚴🏻‍♂️♣️👩🏻‍🎓✏️🌈🤡🎓👻🐤".map {String($0) }
    
    private var addingEmoji = false
    
    @IBAction func addEmoji(_ sender: Any) {
        // Update internal state to "adding emoji"
        addingEmoji = true
        
        // Reloading section 0 with the prev. addingEmoji=true instruction will show
        // a "input textfield" where the user may add new emojis.
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self) //drag the image
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
            }
            
        }
        
        session.loadObjects(ofClass: NSURL.self) { nsurls in
            if let url = nsurls.first as? URL {
                self.imageFetcher.fetch(url)
            }
            
            
        }
        session.loadObjects(ofClass: UIImage.self) { images in
            if let image = images.first as? UIImage {
                self.imageFetcher.backup = image
            }
            
        }
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    var emojiArtBackgroundImage: (url: URL?, image: UIImage?) {
        get {
            return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set {
            scrollView?.zoomScale = 1.0
            _emojiArtBackgroundImageURL = newValue.url
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
            
        }
    }
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    // Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Section #0: Contains only one cell: either "+" (add) emoji cell, or the "input" textField to add emojis
        // Section #1: The list of emojis
        return 2
    }
    
    // Number of items in section
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        // Section #0: Contains only one cell: either "+" (add) emoji cell, or the "input" textField to add emojis
        case 0: return 1
        // Section #1: The list of emojis
        case 1: return emojis.count
        // Should not occur
        default: return 0
        }
    }
    
    private var font: UIFont {
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0)) //for accessibility
    }
    
    // Get cell for item at given indexPath
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // List of emojis available
        if indexPath.section == 1 {
            // Dequeue a reusable emoji-cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            
            // Make sure it is the expected EmojiCollectionViewCell type
            if let emojiCell = cell as? EmojiCollectionViewCell {
                // Create attributed-string with the proper emoji and the predefined font
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font: font])
                
                // Setup cell
                emojiCell.label.attributedText = text
            }
            
            return cell
        }
            // If we're not in section 1, and we are adding an emoji, we want to show the "EmojiInputCell" cell
        else if addingEmoji {
            // Add emoji cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiInputCell", for: indexPath)
            
            // Must be of type TextFieldCollectionViewCell
            if let inputCell = cell as? TextFieldCollectionViewCell {
                
                // Resignation handler gets called when editing of the textField ends
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    
                    // Get the text we want to add
                    if let text = inputCell.textField.text {
                        // Add list of emojis (characters) to the beginning of `emojis`
                        self?.emojis = ((text.map{ String($0)}) + self!.emojis).uniquified
                    }
                    // We're no longer adding emojis
                    self?.addingEmoji = false
                    // We want to reload the view/table since the model changed
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        }
            // If we are not adding an emoji, show the "+" (add) emoji cell
        else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
        }
    }
    
    // Size for item at indexPath
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // If we're adding an emoji, we want to show the input cell wider than usual
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        }
            // Regular cells have a fixed size of NxN
        else {
            return CGSize(width: 80, height: 80)
        }
    }
    
    // Will display cell at indexPath
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // If we're about to display the TextFieldCollectionViewCell cell, we want to show the keyboard.
        if let inputCell = cell as? TextFieldCollectionViewCell {
            // Show keyboard
            inputCell.textField.becomeFirstResponder()
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        } else {
            return []
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1 {
            let isSelf = session.localDragSession?.localContext as? UICollectionView == collectionView
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items { //for inside items
            if let sourceIndexPath = item.sourceIndexPath {
                if let attributedString = item.dragItem.localObject as? NSAttributedString {
                    collectionView.performBatchUpdates( {
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    //do batch update if you do multiple updates to tableview or collectionview
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                    
                }
            } else { //this is for outside item
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { (provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString {
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    var emojiArtView = EmojiArtView()
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
