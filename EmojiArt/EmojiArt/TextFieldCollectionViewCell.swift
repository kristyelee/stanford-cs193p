//
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Kristy Lee on 7/24/19.
//  Copyright © 2019 Kristy Lee. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell, UITextFieldDelegate {
    
    ///
    /// This is called inside `textFieldDidEndEditing`.
    ///
    /// You may set this to do custom things when the text field ends editing.
    ///
    var resignationHandler: (()->Void)?
    
    @IBOutlet weak var textField: UITextField! {
        didSet {
            textField.delegate = self
        }
    }
    
    ///
    /// Text field ended editing
    ///
    func textFieldDidEndEditing(_ textField: UITextField) {
        // If user provided a resignationHandler, call it
        resignationHandler?()
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
