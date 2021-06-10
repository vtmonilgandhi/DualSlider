//
//  DualSliderTests.swift
//  DualSliderTests
//
//  Created by Monil Gandhi on 10/06/21.
//

import XCTest
@testable import DualSlider

class DualSliderTests: XCTestCase {

    var slider = RheemSlider()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func InitSlder() {
        slider.initAutoSlider(forSliderDirection: .vertical,
                              minValue: CGFloat(0),
                              maxValue: CGFloat(100),
                              heatMaxVal: CGFloat(90),
                              coolMinVal: CGFloat(52),
                              coolingValue: CGFloat(85),
                              heatingValue: CGFloat(60),
                              deadBand: CGFloat(5))
    }

}
