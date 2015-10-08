//
//  EmblemView.swift
//  Noter
//
//  Created by hyouuu on 11/11/14.
//

import Foundation

@objc class EmblemView: UIView, CLLocationManagerDelegate {
  let edgePad = 6.f
  let weatherImageSide = 46.f

  var timer: NSTimer!
  // Fire every 45 seconds is good enough for the clock which only care about minute
  let timerIntervalInSec = 45
  var timerFireCount = 0
  let weatherUpdateIntervalInMinute: Int = 30
  var lastWeatherUpdateDate = NSDate()
  var lastLocationUpdateDate = NSDate()

  let timeLabel = UILabel()
  let dateLabel = UILabel()

  let weatherImageView = UIImageView()
  let weatherLabel = UILabel()
  let temperatureLabel = UILabel()
  var isFahrenheit: Bool = isOption(kOptIsFahrenheit)
  var isWeatherServiceDown = NO

  let weatherAPI: OWMWeatherAPI
  let locManager = CLLocationManager()
  let activityIndicator: UIActivityIndicatorView!

  func timeUp() {
    let now = NSDate()
    timeLabel.text = stringFromDate(now, format: timeFormat())
    timeLabel.text = lowercaseTime(timeLabel.text)
    dateLabel.text = stringFromDate(now, format: smartDateFormat(now))

    timerFireCount++
    if (timerIntervalInSec * timerFireCount > weatherUpdateIntervalInMinute * 60) {
      timerFireCount = 0
      updateWeather()
    }
  }

  func setupClock() {
    timer = NSTimer(timeInterval: timerIntervalInSec.t, target: self, selector: "timeUp", userInfo: nil, repeats: YES)
    NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    timeUp()
  }

  func updateWeather() {
    weatherAPI.setTemperatureFormat(isFahrenheit ? kOWMTempFahrenheit : kOWMTempCelcius)
    lastWeatherUpdateDate = NSDate()
    locManager.startUpdatingLocation()
  }

  func updateOrient() {
    isLandscape()
    let halfWidth = screenWidth() / 2
    let halfWidthMinusPad = halfWidth - edgePad * 2

    timeLabel.frame = CGRectMake(edgePad, 15, halfWidthMinusPad, 40)
    dateLabel.frame = CGRectMake(edgePad, 40, halfWidthMinusPad, 40)

    weatherImageView.frame = CGRectMake(
      halfWidth * 1.5 - weatherImageSide / 2,
      8,
      weatherImageSide,
      weatherImageSide)
    weatherLabel.frame = CGRectMake(halfWidth + edgePad, 5, halfWidthMinusPad, 50)
    activityIndicator.center = weatherLabel.center
    temperatureLabel.frame = CGRectMake(halfWidth + edgePad, 51, halfWidthMinusPad, 20)
  }

  func constructWeatherLabel(coordinate: CLLocationCoordinate2D) {
    weatherAPI.currentWeatherByCoordinate(coordinate, withCallback: {
      [weak self]
      (error: NSError!, result: [NSObject: AnyObject]!) in
      if let s = self {
        s.activityIndicator.stopAnimating()
        if result == nil || error != nil {
          return
        }
        // http://bugs.openweathermap.org/projects/api/wiki/Weather_Condition_Codes
        var temp = "--"
        var code = -1
        var desc = ""
        var icon = ""
        if let mainResult = result["main"] as? NSDictionary {
          if let newTemp = mainResult["temp"] as? Float {
            temp = (NSString(format:"%.1f", newTemp) as String) + (s.isFahrenheit ? "℉" : "℃")
            s.temperatureLabel.text = temp
          }
        }
        if let newWeather: NSArray = result["weather"] as? NSArray {
          if newWeather.count > 0 {
            let weather = newWeather[0] as! NSDictionary
            if let newCode = weather["id"] as? String {
              if let intCode = Int(newCode) {
                code = intCode
              }
            }
            if let newDesc = weather["description"] as? String {
              desc = newDesc
            }
            if let newIcon = weather["icon"] as? String {
              icon = newIcon
            }

            // 900s contains extreme & special weather conditions
            if code >= 900 {
              if code >= 950 && code <= 956 {
                icon = "windy"
              } else {
                // Extreme - show desc instead
                icon = ""
                s.weatherLabel.text = desc
              }
            } else if !icon.isEmpty {
              let curHour = getCurDateComponents().hour
              let isDaytime = curHour > 6 && curHour < 19
              icon = icon.substringToIndex(icon.length - 1) + (isDaytime ? "d" : "n")
            }

            if icon.isEmpty {
              s.isWeatherServiceDown = YES
            } else {
              s.weatherImageView.image = pendoImage("Weather/\(icon)")
              s.isWeatherServiceDown = NO
            }
          }
        }
      }
    })
  }

  func setupLocationManager() {
    if #available(iOS 8.0, *) {
      locManager.requestWhenInUseAuthorization()
    }
    locManager.delegate = self
    locManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    updateWeather()
  }

  // CLLocationManagerDelegate
  func locationManager(
    manager: CLLocationManager!,
    didChangeAuthorizationStatus
    status: CLAuthorizationStatus)
  {
    if (CLLocationManager.authorizationStatus() == .Denied) {
      weatherLabel.text = local("locationDenied")
      activityIndicator.stopAnimating()
    } else {
      updateWeather()
    }
  }

  func locationManager(
    manager: CLLocationManager!,
    didUpdateToLocation newLocation: CLLocation!,
    fromLocation oldLocation: CLLocation!)
  {
    locManager.stopUpdatingLocation()
    constructWeatherLabel(newLocation.coordinate)
  }

  override init(frame: CGRect) {
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    weatherAPI = OWMWeatherAPI(APIKey:"Your APIKey")

    super.init(frame: frame)

    timeLabel.textAlignment = .Center
    timeLabel.textColor = UIColor.blackColor()
    timeLabel.font = UIFont(name: "AppleSDGothicNeo-Light", size: 16)
    timeLabel.adjustsFontSizeToFitWidth = YES
    timeLabel.minimumScaleFactor = 0.1
    addSubview(timeLabel)

    dateLabel.textAlignment = .Center
    dateLabel.textColor = UIColor.brownColor()
    dateLabel.text = "Loading Date...";
    dateLabel.font = UIFont(name: "Helvetica", size: 14)
    dateLabel.adjustsFontSizeToFitWidth = YES;
    dateLabel.minimumScaleFactor = 0.1;
    addSubview(dateLabel)

    weatherLabel.textAlignment = .Center
    weatherLabel.textColor = UIColor.lightGrayColor()
    weatherLabel.font = UIFont(name: "Helvetica", size: 12)
    weatherLabel.lineBreakMode = .ByWordWrapping
    weatherLabel.adjustsFontSizeToFitWidth = YES;
    addSubview(weatherLabel)

    addSubview(weatherImageView)

    weatherAPI.setLangWithPreferedLanguage()

    temperatureLabel.textAlignment = .Center
    temperatureLabel.textColor = UIColor.lightGrayColor()
    temperatureLabel.font = UIFont(name: "Helvetica", size:14)
    temperatureLabel.adjustsFontSizeToFitWidth = YES
    temperatureLabel.text = "--" + (isFahrenheit ? "℉" : "℃");
    addSubview(temperatureLabel);

    activityIndicator.center = CGPointMake(0, 0)
    activityIndicator.hidesWhenStopped = YES
    addSubview(activityIndicator)
    activityIndicator.startAnimating()

    observe(
      self,
      selector: "updateOrient",
      name: UIApplicationDidChangeStatusBarOrientationNotification)

    updateOrient()
    setupClock()
    setupLocationManager()

    if (CLLocationManager.authorizationStatus() == .Denied) {
      weatherLabel.text = local("locationDenied")
      activityIndicator.stopAnimating()
    }
  }

  required init(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
  }

  deinit {
    unobserve(self)
  }
}
