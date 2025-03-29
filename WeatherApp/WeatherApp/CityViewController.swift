//
//  CityListViewController.swift
//  WeatherApp
//
//  Created by Stalin on 29/03/25.
//

import UIKit

class CitiesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var weatherDataArray: [WeatherData] = [] {
        didSet {
            print("weatherDataArray updated to \(weatherDataArray.count) items, instance: \(ObjectIdentifier(self))")
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    var isCelsius = true
    
    // MARK: - Different Presentation Methods
    
    // 1. Present this view controller modally from another view controller
    static func presentModally(from presentingVC: UIViewController, withWeatherData data: [WeatherData]) {
        let citiesVC = CitiesViewController()
        citiesVC.weatherDataArray = data
        citiesVC.modalPresentationStyle = .fullScreen // or .pageSheet, .formSheet, etc.
        citiesVC.modalTransitionStyle = .coverVertical // or .flipHorizontal, .crossDissolve
        presentingVC.present(citiesVC, animated: true)
    }
    
    // 2. Push onto navigation stack
    static func pushOntoNavigationStack(from navigationController: UINavigationController, withWeatherData data: [WeatherData]) {
        let citiesVC = CitiesViewController()
        citiesVC.weatherDataArray = data
        navigationController.pushViewController(citiesVC, animated: true)
    }
    
    // 3. Present as popover
    static func presentAsPopover(from sourceView: UIView, in sourceVC: UIViewController, withWeatherData data: [WeatherData]) {
        let citiesVC = CitiesViewController()
        citiesVC.weatherDataArray = data
        citiesVC.modalPresentationStyle = .popover
        citiesVC.preferredContentSize = CGSize(width: 300, height: 400)
        
        if let popover = citiesVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = .any
            popover.delegate = sourceVC as? UIPopoverPresentationControllerDelegate
        }
        
        sourceVC.present(citiesVC, animated: true)
    }
    
    // 4. Custom transition
    static func presentWithCustomTransition(from presentingVC: UIViewController, withWeatherData data: [WeatherData]) {
        let citiesVC = CitiesViewController()
        citiesVC.weatherDataArray = data
        
        // Create a custom transition
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = .moveIn
        transition.subtype = .fromRight
        
        // Add the transition to the window
        presentingVC.view.window?.layer.add(transition, forKey: kCATransition)
        
        // Present the view controller (without animation since we're using custom)
        citiesVC.modalPresentationStyle = .fullScreen
        presentingVC.present(citiesVC, animated: false)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        view.backgroundColor = .systemTeal
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "WeatherCell")
        tableView.rowHeight = 60
        print("CitiesViewController loaded with \(weatherDataArray.count) items, instance: \(ObjectIdentifier(self))")
        
        // Add a close button if presented modally
        if presentingViewController != nil {
            let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissVC))
            navigationItem.rightBarButtonItem = closeButton
        }
        
        tableView.reloadData()
    }
    
    @objc private func dismissVC() {
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will appear, current weatherDataArray count: \(weatherDataArray.count), instance: \(ObjectIdentifier(self))")
        tableView.reloadData()
    }
    
    // MARK: - UITableViewDataSource and UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = weatherDataArray.count
        print("Table view row count: \(count), instance: \(ObjectIdentifier(self))")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WeatherCell", for: indexPath)
        let weather = weatherDataArray[indexPath.row]
        
        cell.textLabel?.text = weather.city
        let tempC = Int(weather.tempC)
        let tempF = Int(weather.tempF)
        cell.viewWithTag(100)?.removeFromSuperview() // Remove any previous temp label if exists
        let tempLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        tempLabel.tag = 100
        tempLabel.text = "\(weather.condition), \(tempC)°C / \(tempF)°F"
        tempLabel.textAlignment = .right
        tempLabel.textColor = .white
        tempLabel.font = .systemFont(ofSize: 14)
        tempLabel.numberOfLines = 2
        cell.contentView.addSubview(tempLabel)
        
        tempLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tempLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -10),
            tempLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            tempLabel.widthAnchor.constraint(equalToConstant: 150),
            tempLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        cell.imageView?.tintColor = .systemYellow
        
        print("Configured cell for \(weather.city) with condition and temp \(weather.condition), \(tempC)°C / \(tempF)°F, instance: \(ObjectIdentifier(self))")
        return cell
    }
}
