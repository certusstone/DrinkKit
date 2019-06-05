//
//  HealthKitHelper.swift
//
// Created: 5/10/19
//

import Foundation
import HealthKit

public class HealthKitHelper {
  /// Sets the type of thing we're logging to `dietaryWater`
  static let waterType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryWater)
  
  /**
   gets an array of `HKQuantitySample`s that were logged between the start and end dates.
   
   - Parameters:
      - startDate: the earliest date to look for samples.
      - endDate: the latest date to look for samples.
   
   - Returns: an array of `HKQuantitySample`s that were logged between the start and end dates.
   */
  public class func getSamplesBetweenDates(startDate: Date, endDate: Date) -> [HKQuantitySample] {
      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
      return getSamplesWithPredicate(predicate: predicate)
  }
  
  /**
   gets all the samples that match the predicate and have the `sampleType` of `waterType`.
   
   - Parameters:
      - predicate: the `NSPredicate` that should be matched.
   
   - Returns: an array of `HKQuantitySample`s that match the predicate and have the proper type.
   */
  public class func getSamplesWithPredicate(predicate: NSPredicate) -> [HKQuantitySample] {
      guard waterType != nil else {
          fatalError("Dietary Water is no longer available in HealthKit")
      }
        
      let queryGroup = DispatchGroup()
      var returnValue = [HKQuantitySample]()
      let query = HKSampleQuery(sampleType: waterType!, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: nil) {
            query, results, error in
            
          guard let samples = results as? [HKQuantitySample] else {
              fatalError("An error occured fetching the user's water: \(String(describing: error?.localizedDescription))");
          }
          returnValue = samples
          queryGroup.leave()
      }
      queryGroup.enter()
      HKHealthStore().execute(query)
      queryGroup.wait()
      return returnValue
    }
  
  /**
   saves a water sample in Health Kit.
   
   - Parameters:
      - quantity: the quantity of water to save.
      - date: the date the water should be logged as. Defaults to the current date.
   
   - Returns: true if successful, false if not.
   */
  public class func saveWaterSample(quantity: HKQuantity, date: Date = Date()) -> Bool {
    let saveGroup = DispatchGroup()
    guard waterType != nil else {
      fatalError("Dietary Water is no longer available in HealthKit")
    }
    var returnValue = true
    let sample = HKQuantitySample(type: waterType!, quantity: quantity, start: date, end: date)
    saveGroup.enter()
    HKHealthStore().save(sample) { (success, error) in
      if let error = error {
        print("Error Saving Sample: \(error.localizedDescription)")
        returnValue = false
      }
      saveGroup.leave()
    }
    saveGroup.wait()
    return returnValue
  }
  
  /**
   Deletes a water sample from Health Kit.
   
   - Parameters:
     - date: the date that the water sample is associated with.
   
   - Returns: true if successful, false if not.
   */
  public class func deleteWaterSample(date: Date) -> Bool {
    let deleteGroup = DispatchGroup()
    guard waterType != nil else {
      fatalError("Dietary Water is no longer available in HealthKit")
    }
    var returnValue = true
    let cal = Calendar.current
    var components = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    components.second = components.second! + 1
    let endDate = cal.date(from: components)
    components.second = components.second! - 2
    let startDate = cal.date(from: components)
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
    deleteGroup.enter()
    HKHealthStore().deleteObjects(of: waterType!, predicate: predicate, withCompletion: {(success, i, error) -> Void in
      if let error = error {
        print("Error deleting sample: \(error.localizedDescription)")
        returnValue = false
      }
      deleteGroup.leave()
    })
    deleteGroup.wait()
    return returnValue
  }
}
