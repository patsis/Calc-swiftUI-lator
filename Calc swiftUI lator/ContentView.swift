//
//  ContentView.swift
//  Calc swiftUI lator
//
//  Created by Harry Patsis on 10/11/19.
//  Copyright © 2019 Harry Patsis. All rights reserved.
//

import SwiftUI
extension String {
  func toDouble() -> Double {
    if let double = Double(self) {
      return double
    } else {
      return 0
    }
  }
}
extension Double {
  func toString() -> String {
    let fmt = NumberFormatter()
    fmt.locale = Locale(identifier: "en_US_POSIX")
    fmt.numberStyle = (abs(self) > 1e+16) ? .scientific : .decimal
    fmt.generatesDecimalNumbers = true
    fmt.usesSignificantDigits = true
    fmt.usesGroupingSeparator = true
    fmt.maximumSignificantDigits = 100
    fmt.groupingSize = 3
    fmt.groupingSeparator = ","
    fmt.maximumIntegerDigits = 100
    fmt.maximumFractionDigits = 100
    fmt.minimumFractionDigits = 0
    return fmt.string(for: self)!
    //    return String(format: "%.12g",self)
  }
}

enum ButtonType {
  case number
  case operation
  case control
  case function
}

struct CalcButtonColor {
  let text: Color
  let dark: Color
  let light: Color
}

extension Color {
  init(_ hex: UInt32, opacity:Double = 1.0) {
    let red = Double((hex & 0xff0000) >> 16) / 255.0
    let green = Double((hex & 0xff00) >> 8) / 255.0
    let blue = Double((hex & 0xff) >> 0) / 255.0
    self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
  }
}

struct CalcButtonStyle: ButtonStyle {
  var type : ButtonType
  var width : CGFloat = 1
  var height : CGFloat = 1
  var pad : CGFloat = 20
  let colors = [
    ButtonType.number    : CalcButtonColor(text: .white, dark: Color(0x232526), light: Color(0x414345)),
    ButtonType.operation : CalcButtonColor(text: .white, dark: Color(0xFF8008), light: Color(0xffa84c)),
    ButtonType.control   : CalcButtonColor(text: .white, dark: Color(0xb83737), light: Color(0xff5858)),
    ButtonType.function  : CalcButtonColor(text: .white, dark: Color(0x414345), light: Color(0x616365))
  ]
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .frame(width: 2 * (width - 1) * (pad + 5.0) + width * 40, height: 40, alignment: .center)
      .padding(pad)
      .foregroundColor(colors[type]!.text)
      .background(LinearGradient(gradient: Gradient(colors: [colors[type]!.light, colors[type]!.dark]), startPoint: .top, endPoint: .bottom))
      .cornerRadius(20)
      .shadow(color: Color(white: 0, opacity: 0.3), radius: 5.0, x: 2, y: 2 )
      .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
      .padding(5)
  }
}

struct CalcButton: View {
  var text: String
  var type: ButtonType
  var width:CGFloat = 1
  var height:CGFloat = 1
  var action: (String) -> Void
  var body: some View {
    Button(action: {
      // What to perform
      self.action(self.text)
    }) {
      Text(text)
        .fontWeight(.bold)
        .font(.title)
    }.buttonStyle(CalcButtonStyle(type: type, width: width, height: height))
    
  }
}

struct ContentView: View {
  @State var value: String = "0"
  @State var operand: Double? = nil
  @State var operation: String? = nil
  @State var needsOperand: Bool =  true
  @State var lastOperand: Double? = nil
  
  private var performCalculation: Dictionary<String, (Double, Double) -> Double> = [
    "+": { $0 + $1 },
    "-": { $0 - $1 },
    "×": { $0 * $1 },
    "÷": { $0 / $1 },
    "±": { -$1 },
    "%": { $1 * 0.01},
    "=": { $1 }
  ]
  
  func doFunction(function: String) {
    if let calculation = performCalculation[function] {
      let result = calculation(0, value.toDouble())
      value = result.toString()
    }
    if (needsOperand) {
      operand = value.toDouble()
    }
  }
  
  func doEqual() {
    if (operand == nil) {
      operand = value.toDouble()
    } else if (operation != nil) {
      if (lastOperand == nil) {
        lastOperand = value.toDouble()
      }
      let firstValue = operand ?? 0
      if let calculation = performCalculation[operation!] {
        value = calculation(firstValue, value.toDouble()).toString()
      }
      operand = lastOperand
      needsOperand = true
    }
  }
  
  func doOperation(newOperation: String) {
    if (operation != nil && needsOperand)  {
      operand = value.toDouble()
      operation = newOperation;
      return;
    }

    if (operand == nil) {
      operand = value.toDouble()
    } else if (operation != nil) {
      let firstValue = operand ?? 0
      if let calculation = performCalculation[operation!] {
        value = calculation(firstValue, value.toDouble()).toString()
      }
      operand = value.toDouble()
    }
    
    needsOperand = true
    operation = newOperation
  }
  
  func buttonHandler(_ text: String) {
    switch text {
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
      if (needsOperand) {
        needsOperand = false
        value = text
      } else {
        value = value + text
      }
      lastOperand = nil
    case ".":
      if (!value.contains(",")) {
        value = value + text
      }
    case "+", "-", "×", "÷":
      doOperation(newOperation: text)
    case "=":
      doEqual()
    case "±", "%":
      doFunction(function: text)
    case "C":
      value = "0"
      operand = nil
      operation = nil
      needsOperand = true
    default :
      break;
    }
  }
  
  var body: some View {
    // numbers
    VStack {
      Spacer()
      Text(value)
        .minimumScaleFactor(CGFloat(0.1))
        .lineLimit(1)
        .font(.system(size: 100))
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
        .padding()
      
      HStack(spacing: 0) {
        CalcButton(text: "C", type: .control, action: buttonHandler)
        CalcButton(text: "±", type: .function, action: buttonHandler)
        CalcButton(text: "%", type: .function, action: buttonHandler)
        CalcButton(text: "÷", type: .operation, action: buttonHandler)
      }
      HStack(spacing: 0) {
        CalcButton(text: "7", type: .number, action: buttonHandler)
        CalcButton(text: "8", type: .number, action: buttonHandler)
        CalcButton(text: "9", type: .number, action: buttonHandler)
        CalcButton(text: "×", type: .operation, action: buttonHandler)
      }
      HStack(spacing: 0) {
        CalcButton(text: "4", type: .number, action: buttonHandler)
        CalcButton(text: "5", type: .number, action: buttonHandler)
        CalcButton(text: "6", type: .number, action: buttonHandler)
        CalcButton(text: "-", type: .operation, action: buttonHandler)
      }
      HStack(spacing: 0) {
        CalcButton(text: "1", type: .number, action: buttonHandler)
        CalcButton(text: "2", type: .number, action: buttonHandler)
        CalcButton(text: "3", type: .number, action: buttonHandler)
        CalcButton(text: "+", type: .operation, action: buttonHandler)
      }
      HStack(spacing: 0) {
        CalcButton(text: "0", type: .number, width: 2, action: buttonHandler)
        CalcButton(text: ".", type: .number, action: buttonHandler)
        CalcButton(text: "=", type: .operation, action: buttonHandler)
      }
    }
    .padding(10.0)
  }
}
//×−+÷=
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    //    Group {
    //      ContentView()
    //        .previewDevice(PreviewDevice(rawValue: "iPhone 11 Pro Max"))
    ContentView()
    //        .colorScheme(/*@START_MENU_TOKEN@*/.dark/*@END_MENU_TOKEN@*/)
    //    }
  }
}
