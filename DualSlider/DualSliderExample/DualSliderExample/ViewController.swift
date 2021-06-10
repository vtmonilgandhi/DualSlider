//
//  ViewController.swift
//  DualSliderExample
//
//  Created by Monil Gandhi on 10/06/21.
//

import UIKit
import DualSlider

class ViewController: UIViewController {

    @IBOutlet weak var dualSlider: DualSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dualSlider.initAutoSlider(forSliderDirection: .vertical,
                                  minValue: CGFloat(0),
                                  maxValue: CGFloat(100),
                                  heatMaxVal: CGFloat(90),
                                  coolMinVal: CGFloat(52),
                                  coolingValue: CGFloat(85),
                                  heatingValue: CGFloat(60),
                                  deadBand: CGFloat(5))
    }


}

