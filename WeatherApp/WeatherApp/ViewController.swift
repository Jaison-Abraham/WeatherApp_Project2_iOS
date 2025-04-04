//
//  ViewController.swift
//  WeatherApp
//
//  Created by JAISON ABRAHAM on 2025-03-29.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var weatherImage: UIImageView!
    @IBOutlet weak var tempToggle: UISegmentedControl!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var citiesButton: UIButton!
    
    let locationManager = CLLocationManager()
    var weatherDataArray: [WeatherData] = []
    var isCelsius = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        searchTextField.delegate = self
        print("View loaded successfully, ViewController instance: \(ObjectIdentifier(self))")
    }
    
    func setupUI() {
        view.backgroundColor = UIColor(displayP3Red: 67/255, green: 178/255, blue: 231/255, alpha: 1.0)
        searchTextField.layer.cornerRadius = 10
        searchTextField.textColor = UIColor.black
        searchButton.layer.cornerRadius = 10
        locationButton.layer.cornerRadius = 30
        locationButton.backgroundColor = .systemBlue
        locationButton.setImage(UIImage(systemName: "location.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal), for: .normal)
        locationButton.clipsToBounds = true
        citiesButton.layer.cornerRadius = 12
        tempToggle.layer.cornerRadius = 8
        updateTemperatureDisplay()
        print("UI setup completed")
    }
    
    @IBAction func searchTapped(_ sender: UIButton) {
        if let city = searchTextField.text?.trimmingCharacters(in: .whitespaces), !city.isEmpty {
            print("Searching for: \(city)")
            fetchWeather(for: city)
        } else {
            print("Search field is empty or invalid")
        }
    }
    
    @IBAction func locationTapped(_ sender: UIButton) {
        locationManager.requestLocation()
    }
    
    @IBAction func toggleChanged(_ sender: UISegmentedControl) {
        isCelsius = sender.selectedSegmentIndex == 0
        updateTemperatureDisplay()
    }
    
    func fetchWeather(for city: String) {
        let apiKey = "cc13be92af664e31a5f63640251403"
        let urlString = "https://api.weatherapi.com/v1/current.json?key=\(apiKey)&q=\(city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city)"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("API request failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received from API")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            do {
                let weather = try JSONDecoder().decode(WeatherResponse.self, from: data)
                let weatherData = WeatherData(
                    city: weather.location.name,
                    tempC: weather.current.temp_c,
                    tempF: weather.current.temp_f,
                    condition: weather.current.condition.text,
                    conditionCode: weather.current.condition.code
                )
                
                DispatchQueue.main.async {
                    self?.weatherDataArray.append(weatherData)
                    self?.updateUI(with: weatherData)
                }
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed JSON: \(jsonString)")
                }
            }
        }.resume()
    }
    
    func updateUI(with weather: WeatherData) {
        locationLabel.text = weather.city
        conditionLabel.text = weather.condition
        updateTemperatureDisplay()
        weatherImage.image = getWeatherSymbol(for: weather.conditionCode)
    }
    
    func updateTemperatureDisplay() {
        if let currentWeather = weatherDataArray.last {
            let temp = isCelsius ? currentWeather.tempC : currentWeather.tempF
            let unit = isCelsius ? "°C" : "°F"
            tempLabel.text = "\(Int(temp))\(unit)"
        } else {
            tempLabel.text = isCelsius ? "0°C" : "0°F"
            print("No weather data, showing default: \(tempLabel.text ?? "N/A")")
        }
    }
    
    func getWeatherSymbol(for code: Int) -> UIImage? {
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .systemBlue])
        switch code {
        case 1000: return UIImage(systemName: "sun.max.fill")?.withConfiguration(config)
        case 1003: return UIImage(systemName: "cloud.sun.fill")?.withConfiguration(config)
        case 1006, 1009: return UIImage(systemName: "cloud.fill")?.withConfiguration(config)
        case 1063, 1180, 1183, 1186, 1189: return UIImage(systemName: "cloud.rain.fill")?.withConfiguration(config)
        case 1066, 1210, 1213, 1216, 1219: return UIImage(systemName: "cloud.snow.fill")?.withConfiguration(config)
        case 1030, 1135: return UIImage(systemName: "cloud.fog.fill")?.withConfiguration(config)
        case 1087, 1273, 1276: return UIImage(systemName: "cloud.bolt.fill")?.withConfiguration(config)
        default: return UIImage(systemName: "cloud.fill")?.withConfiguration(config)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCities",
           let navigationController = segue.destination as? UINavigationController,
           let destination = navigationController.topViewController as? CitiesViewController {
            destination.weatherDataArray = weatherDataArray
            destination.isCelsius = isCelsius
            print("Passing data to CitiesViewController: \(weatherDataArray.count) items, isCelsius: \(isCelsius), destination instance: \(ObjectIdentifier(destination))")
        }
    }
}

extension ViewController: CLLocationManagerDelegate, UITextFieldDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                if let city = placemarks?.first?.locality {
                    self?.fetchWeather(for: city)
                } else {
                    print("Geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            print("Location permission granted, requesting location")
        } else {
            print("Location permission denied: \(status.rawValue)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchTapped(searchButton)
        return true
    }
}

struct WeatherResponse: Codable {
    let location: Location
    let current: Current
    
    struct Location: Codable {
        let name: String
    }
    
    struct Current: Codable {
        let temp_c: Double
        let temp_f: Double
        let condition: Condition
        
        struct Condition: Codable {
            let text: String
            let code: Int
        }
    }
}
