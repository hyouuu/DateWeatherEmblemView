# DateWeatherEmblemView
An UICollectionView's emblem view with date (time) and weather information, as used in Pendo 1.x 

# Usage
In your UICollectionViewController, define something like:
```
  var emblemView = EmblemView(frame: CGRectMake(0, -55, screenWidth(), 50))
  
  override func viewDidLoad() {
    super.viewDidLoad()
    ...
    emblemView.isFahrenheit = false
    emblemView.updateWeather()
    collectionView.addSubview(emblemView)
    collectionView.contentInset.top += emblemView.frame.height
    ...
  }
```  

You'll also need a list of weather icons, as used bye the line:
```
  s.weatherImageView.image = pendoImage("Weather/\(icon)")
```
where pendoImage("Weather/\(icon)") is loading the corresponding image file

# Helpers
There are some helpers used in the code, and here are the bodies: (let me know if I missed any)

```
func observe(observer: AnyObject, selector sel: Selector, name aName: String?, object: AnyObject? = nil) {
  NSNotificationCenter.defaultCenter().addObserver(
    observer,
    selector: sel,
    name: aName,
    object: object)
}

func unobserve(observer: AnyObject, name: String? = nil) {
  NSNotificationCenter.defaultCenter().removeObserver(observer, name: name, object: nil)
}

var _isLandscape = NO
func isLandscapeNoCheck () -> Bool {
  return _isLandscape
}

func isLandscape () -> Bool {
  let orientation = UIApplication.sharedApplication().statusBarOrientation

  if !isPad && orientation == .PortraitUpsideDown {
    return _isLandscape
  }

  if (UIInterfaceOrientationIsLandscape(orientation)) {
    _isLandscape = YES
  } else if (UIInterfaceOrientationIsPortrait(orientation)) {
    _isLandscape = NO
  } else {
    // FaceUp / FaceDown etc just return
    return _isLandscape
  }

  // Reset them so it will be updated
  _screenHeight = 0
  _screenWidth = 0

  return _isLandscape
}

// These 2 methods need a isLandscape call first
var _screenWidth = 0.f
var _screenHeight = 0.f
func screenWidth () -> CGFloat {
  if (_screenWidth <= 0) {
    if (_isLandscape) {
      _screenWidth = deviceHeight
    } else {
      _screenWidth = deviceWidth
    }
  }

  return _screenWidth
}

func screenHeight () -> CGFloat {
  if (_screenHeight <= 0) {
    if (_isLandscape) {
      _screenHeight = deviceWidth
    } else {
      _screenHeight = deviceHeight
    }
  }

  return _screenHeight
}
```
