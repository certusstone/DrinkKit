//
// DrinkKit.swift
//
// Created: 5/10/19
//

import Foundation
import HealthKit

public class DrinkKit {
  public init() {
  }
  
  enum WaterError: Error {
    case HealthKitAddFail
    case HealthKitDeleteFail
  }
  
  /**
   adds a drink of water to Health Kit.
   
   - Parameters:
      - amount: the amount of water.
      - unit: the `HKUnit` to be applied to the amount of water. (Usually `.ml` or `.oz`)
      - date: the date that the water had been drunk. Defaults to the current day.
      - completion: what to do after the drink has been added to Health Kit.
   
   - Throws: throws `HealthKitAddFail` if Health Kit cannot add the drink.
 */
  public func addDrink(amount: Double, unit: HKUnit, date: Date = Date(), completion:(() -> Void)?) throws {
    let mlAmount = (unit == .ml) ? amount : ozToMl(oz: amount)
    if mlAmount > 0 {
      let quantity = HKQuantity(unit: .ml, doubleValue: mlAmount)
      guard HealthKitHelper.saveWaterSample(quantity: quantity, date: date) else {
        throw WaterError.HealthKitAddFail
      }
    }
    if completion != nil { completion!() }
  }
  /**
   Deletes a drink from Health Kit.
   
   - Parameters:
      - date: the date that the drink in question is associated with.
      - completion: what to do after the drink has been deleted from Health Kit.
   
   - Throws: throws `HealthKitDeleteFail` if Health Kit cannot add the drink.
   
   */
  public func deleteDrink(date: Date, completion:(() -> Void)?) throws {
    guard HealthKitHelper.deleteWaterSample(date: date) else {
      throw WaterError.HealthKitDeleteFail
    }
    if completion != nil { completion!() }
  }
  
  /**
   changes a drink at a specified date into a drink with different values in Health Kit.
   
   deletes the drink that we want to change and adds a new one
   
   - Parameters:
       - date: the date that the drink in question is associated with.
       - newAmount: the amount that the new drink should have
       - newUnit: the `HKUnit` to be applied to the amount of water. (Usually `.ml` or `.oz`)
       - completion: what to do after the drink has been changed in Health Kit.
   
   - Throws:
      - throws `HealthKitDeleteFail` if Health Kit does not delete the drink
      - throws `HealthKitAddFail` if Health Kit does not add the new drink
 */
  public func changeDrink(date: Date, newAmount amount: Double, newUnit unit: HKUnit, completion:(() -> Void)?) throws {
    try deleteDrink(date: date, completion: completion)
    try addDrink(amount: amount, unit: unit, date: date, completion: completion)
  }
  
  /**
   gets an array of all the drinks that the user logged on a certain day in Health Kit.
   
   - Parameters:
      - date: the date that the drinks were logged on. Defaults to the current day.
 
   - Returns: an array of `HKQuantitySample` representing the drinks that were logged in Health Kit on the date.
   */
  public func getDrinksFrom(date: Date = Date()) -> [HKQuantitySample] {
    let samples = HealthKitHelper.getSamplesBetweenDates(startDate: getStartOfDay(date: date), endDate: getEndOfDay(date: date))
    return samples
  }
  
  /**
   get the total amount of water logged on a certain day in Health Kit.
   
   uses the `getDrinksFrom` method to get all the drinks on a day and totals the double values
   
   - Parameters:
      - date: the date that the drinks were logged on.
   
   - Returns: a `HKQuantity` representing the total amount of water logged on the date.
 */
  public func getTotalFrom(date: Date) -> HKQuantity {
    let samples = getDrinksFrom(date: date)
    var current = 0.0
    for sample in samples {
      current += sample.quantity.doubleValue(for: .ml)
    }
    return HKQuantity(unit: .ml, doubleValue: current)
  }
  
  /**
   get the total amount of water logged in Health Kit today.
   
   - Returns: a `HKQuantity` representing the total amount of water logged today.
 */
  public func getTotalToday() -> HKQuantity {
    return getTotalFrom(date: Date())
  }
  
  /**
   get the total amount of water logged in Health Kit today.
   
   - Returns: the `Double` value of the amount of water logged today.
 */
  public func getTotalToday() -> Double {
    return getTotalFrom(date: Date()).doubleValue(for: .ml)
  }
  
  //MARK: Helper Functions
  
  /**
   converts a `Double` representing a number of Ounces into a `Double` representing the same volume in Milliliters.
   
   - Parameters:
      - oz: the number of Ounces to be converted to Milliliters.
   
   - Returns: the number of Milliliters that was converted from Ounces.
 */
  private func ozToMl(oz: Double) -> Double {
    var ml = oz * 29.5735
    return ml.roundTo(precision: 0)
  }
  
  /**
   gets 00:00:00 of a specified date
   
   - Parameters:
      - date: the date to get 00:00:00 of. Defaults to the current day.
   
   - Returns: the `Date` of 00:00:00 of the date in question.
 */
  private func getStartOfDay(date: Date = Date()) -> Date {
    let cal: Calendar = Calendar(identifier: .gregorian)
    let newDate: Date = cal.date(bySettingHour: 0, minute: 0, second: 0, of: date)!
    return newDate
  }
  
  /**
   gets 00:00:00 of the day after the specified date
   
   - Parameters:
      - date: the day before the date to get 00:00:00 of. Defaults to the current day.
   
   - Returns: the `Date` of 00:00:00 of the day after the date in question.
 */
  private func getEndOfDay(date: Date = Date()) -> Date {
    let cal: Calendar = Calendar(identifier: .gregorian)
    let nextDay = cal.date(byAdding: .day, value: 1, to: getStartOfDay(date: date))!
    return nextDay
  }
  
}

extension HKUnit {
  /// HKUnit.ml = HKUnit(from: "mL")
  static let ml = HKUnit(from: "mL")
  
  /// HKUnit.oz = HKUnit(from: "oz")
  static let oz = HKUnit(from: "oz")
}

extension Double {
  /**
   rounds to the nth decimal place
   
   - Usage:
    ```
    let number = 123.456
    number.roundTo(precision: 1)
    // number = 123.4
    ```
   
   - Parameters:
      - precision: the decimal place to round to. (0 for integer)
   
   - Returns: a double with n decimal places.
 */
  mutating func roundTo(precision: Int) -> Double {
    let divisor = pow(10.0, Double(precision))
    return Darwin.round(self * divisor) / divisor
  }
}
