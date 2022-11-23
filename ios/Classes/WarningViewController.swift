//
//  WarningViewController.swift
//  secure_application
//
//  Created by Balázs Kilvády on 05/13/22.
//

import UIKit

class WarningViewController: UIViewController {
    init(languageCode: String) {
        super.init(nibName: nil, bundle: nil)
        _createView(view, languageCode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension WarningViewController {
    func _createView(_ view: UIView, _ languageCode: String) {
        let imageView = UIImageView(image: UIImage(imageLiteralResourceName: "smile"))
        view.backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let texts: [String]
        switch languageCode {
        case "en":
            texts = _kTexts[1]
        default:
            texts = _kTexts[0]
        }

        let mainLabel = UILabel()
        let auxLabel = UILabel()

        mainLabel.text = texts[0]
        mainLabel.textColor = .black
        mainLabel.font = UIFont.boldSystemFont(ofSize: 18)
        mainLabel.numberOfLines = 0
        mainLabel.textAlignment = .center
        mainLabel.translatesAutoresizingMaskIntoConstraints = false

        auxLabel.text = texts[1]
        auxLabel.textColor = .gray
        auxLabel.font = UIFont.systemFont(ofSize: 14)
        auxLabel.numberOfLines = 0
        auxLabel.textAlignment = .center
        auxLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [imageView, mainLabel, auxLabel])
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 16
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }
}

private let _kTexts = [
    [
        "تسجيل الشاشة غير مسموح",
        "يمكنك إعادة مشاهدة الدورات عدة مرات حسب حاجتك.",
    ],
    [
        "Screen recording is not allowed on our app",
        "You can re-watch the courses as many times as you need.",
    ],
]
