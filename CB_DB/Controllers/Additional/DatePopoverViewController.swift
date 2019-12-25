//
//  DatePopoverViewController.swift
//  ScannerEnterprise
//
//  Created by Vladimir Evdokimov on 2019-10-24.
//  Copyright © 2019 Orthogenic Laboratories. All rights reserved.
//

import Foundation
import Calendar_iOS

class DatePopoverViewController: UIViewController, CalendarViewDelegate {
    var date:Date = Date() {
        didSet{
            calendarView?.currentDate = date
        }
    }
    
    var onChangeDate:((Date?) ->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = CGSize(width: 300, height: 300)

        if let view = self.calendarView {
            self.view.addSubview(view)
        }

        self.calendarView?.calendarDelegate = self
        self.calendarView?.shouldShowHeaders = true
        self.calendarView?.shouldMarkSelectedDate = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.calendarView?.refresh()
        calendarView?.currentDate = date
    }
    
    //MARK: - Private
    
    @IBOutlet private weak var calendarView: CalendarView?

    func didChangeCalendarDate(_ date: Date!) {
        onChangeDate?(date)
    }
}
