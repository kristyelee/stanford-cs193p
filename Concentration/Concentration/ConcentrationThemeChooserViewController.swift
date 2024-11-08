//
//  ConcentrationThemeChooserViewController.swift
//  Concentration
//
//  Created by Kristy Lee on 7/18/19.
//  Copyright © 2019 Kristy Lee. All rights reserved.
//

import UIKit

class ConcentrationThemeChooserViewController: UIViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func awakeFromNib() {
        splitViewController?.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if let cvc = secondaryViewController as? ConcentrationViewController {
            if cvc.theme == nil {
                return true
            }
        }
        return false
    }
    
    let themes = [
        "Sports": "⚽️🏀🏈⚾️🎾🏐🏉🎱🏓⛷🎳⛳️",
        "Animals": "🐶🐔🦊🐼🦀🐪🐓🐋🐙🦄🐵",
        "Faces": "😀😂😎😫😰😴🙄🤔😘😷",
        "Halloween": "🦇😱🙀😈🎃👻🍭🍬🍎"
    ]
    
   //this is how you segue from main menu to game in code. I create a SEGUE between the two view controllers
    
    //relevance: you can keep the old MVC (and therefore not always restart the game) when you press one of the labels.
    //with the direct segues, when you change the theme you have to restart the game
    @IBAction func changeTheme(_ sender: Any) {
        if let cvc = splitViewDetailConcentrationViewController {
            if let themeName = (sender as? UIButton)?.currentTitle, let theme = themes[themeName] {
                cvc.theme = theme
            }
       
        } else if let cvc = lastSeguedToConcentrationViewController {
            navigationController?.pushViewController(cvc, animated: true)
        } else {
            performSegue(withIdentifier: "Choose Theme", sender: sender)
        }
        
    }
    
    private var splitViewDetailConcentrationViewController: ConcentrationViewController? { //last is the detail
        return splitViewController?.viewControllers.last as? ConcentrationViewController
    }
    
    private var lastSeguedToConcentrationViewController: ConcentrationViewController?
    
    override func prepare (for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Choose Theme" {
            //could shorten code underneath as if let themeName = (sender as? UIButton)?.currentTitle, let theme = themes[themeName] { ... }
            if let button = sender as? UIButton { //because sender is a optional Any type
                
                if let themeName = button.currentTitle {
                    if let theme = themes[themeName] {
                        if let cvc = segue.destination as? ConcentrationViewController {
                            cvc.theme = theme
                            lastSeguedToConcentrationViewController = cvc
                        }
                    }
                }
            }
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
