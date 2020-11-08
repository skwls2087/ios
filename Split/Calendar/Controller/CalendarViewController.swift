//
//  CalendarViewController.swift
//  Split
//
//  Created by uno on 2020/10/28.
//

import UIKit
import FSCalendar
import Alamofire

class CalendarViewController: UIViewController {
    
    // MARK:- Properties
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgoroundView: UIView!
    
    let userID = UserDefaults.standard.string(forKey: "id")
    var userPlans: [UserPlan] = []
    var userDailyPlan: [UserPlan] = []
    var PlanDates: [[String]] = [[],[],[]]
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    var selectDate: Date?
    
    // MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureTapBar()
        configureCalendar()
        configureTableView()
//        configureBackgoroundView()
        print("유저아이디 : \(userID!)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getUserPlan()
        deselectDate()
    }

}

// MARK:- Configure
extension CalendarViewController {
    
    func configureTapBar() {
        navigationItem.title = "캘린더"
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "KoPubDotumBold", size: 20)!]
    }
    
    func configureCalendar() {
        calendar.dataSource = self
        calendar.delegate = self
        
        calendar.swipeToChooseGesture.isEnabled = true
        calendar.clipsToBounds = true
        calendar.appearance.headerDateFormat = "yyyy.MM"
        calendar.locale = Locale(identifier: "ko")
        
        calendar.appearance.headerMinimumDissolvedAlpha = 0
        calendar.calendarHeaderView.backgroundColor = #colorLiteral(red: 0.2156862745, green: 0.2784313725, blue: 0.3098039216, alpha: 1)
        calendar.appearance.headerTitleColor = .white
        calendar.appearance.headerTitleFont = UIFont(name: "KoPubDotumBold", size: 20)
        calendar.appearance.weekdayTextColor = .black
        calendar.appearance.todayColor = .lightGray
        calendar.appearance.selectionColor = #colorLiteral(red: 0.8666666667, green: 0.6431372549, blue: 0.1647058824, alpha: 1)
    }
    
    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(
            UINib(nibName: "CalendarTableViewCell", bundle: nil),
            forCellReuseIdentifier: "calendarTableViewCell")
    }
    
}

// MARK:- Methods
extension CalendarViewController {
    
    private func getUserPlan() {
        let headers: HTTPHeaders = [
            "memberId": "2",
        ]
        AF.request(CalendarAPIConstant.userPlanURL, headers: headers).responseJSON { (response) in
            switch response.result {
                // 성공
            case .success(let res):
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: res, options: .prettyPrinted)
                    let json = try JSONDecoder().decode([UserPlan].self, from: jsonData)
                    
                    self.userPlans = json
                    DispatchQueue.main.async {
//                        self.tableView.reloadData()
                        self.PlanDates = [[],[],[]]
                        self.setUserPlanDates(userPlans: self.userPlans)
                        self.calendar.reloadData()
                        self.setUserDailyPlan(date: Date())
                        self.tableView.reloadData()
                    }
                } catch(let err) {
                    print(err.localizedDescription)
                }
                // 실패
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
    
    private func deleteUserPlan(planID: Int) {
        // HTTP Request
        let headers: HTTPHeaders = [
            "plan_log_id": "\(planID)"
        ]
        AF.request(PlanAPIConstant.userPlanDeleteURL, method: .post, headers: headers).responseJSON { (response) in
            switch response.result {
                // 성공
            case .success(let res):
                print("성공: \(res)")
                // 실패
            case .failure(let err):
                print("실패: \(err.localizedDescription)")
            }
        }
    }
    
    func checkPlanProgress(status: String) -> String {
        switch status {
        case "SUCCESS":
            return "성공"
        case "FAIL":
            return "실패"
        case "ONGOING":
            return "진행"
        default:
            return "진행"
        }
    }
    
    func deletePlan(planID: Int) {
        let alert = UIAlertController(
            title: "",
            message: "정말로 플랜신청 내역을 삭제하시겠습니까?",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "확인",
            style: .default) { (action : UIAlertAction) in
            self.deleteUserPlan(planID: planID)
            self.completeAlert()
            self.getUserPlan()
        }
        let cancelAction = UIAlertAction(
            title: "취소",
            style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func completeAlert() {
        let alert = UIAlertController(
            title: "",
            message: "플랜이 삭제되었습니다.",
            preferredStyle: .alert)
        let okAction = UIAlertAction(
            title: "확인",
            style: .default)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func checkPlanColor(type: Int) -> String {
        switch type {
        case 1:
            return "Color_1day"
        case 7:
            return "Color_7days"
        case 15:
            return "Color_15days"
        case 30:
            return "Color_30days"
        default:
            return "Color_1days"
        }
    }
    
    func checkSuccessColor(status: String) -> UIColor {
        switch status {
        case "ONGOING":
            return UIColor.lightGray
        case "SUCCESS":
            return UIColor.systemBlue
        case "FAIL":
            return UIColor.red
        default:
            return UIColor.lightGray
        }
    }
    
    // 플랜 날짜 리스트 만들기
    func setUserPlanDates(userPlans: [UserPlan]) {
        for i in 0 ..< userPlans.count {
            let startDateString = userPlans[i].startDate
            guard let startDate = dateFormatter.date(from: startDateString) else { return }
            var date = startDate
            for _ in 0..<userPlans[i].needAuthNum {
                PlanDates[i].append(dateFormatter.string(from: date))
                date = date + 86400
            }
        }
        print("setUserPlanDates() called - PlanDates: \(PlanDates)")
    }
    
    // 날짜 선택시 임시 유저플랜 array 세팅
    func setUserDailyPlan(date: Date) {
        // 날짜를 선택할때마다 메서드가 재호출 되는데 재호출시 유저의 데일리 플랜을 초기화해야한다.
        userDailyPlan = []
        let date = dateFormatter.string(from: date)
        for i in 0 ..< userPlans.count {
            if PlanDates[i].contains(date) {
                userDailyPlan.append(userPlans[i])
            }
        }
    }
    
    // 화면 나갔다오면 선택된 날짜 표시 해제하기
    func deselectDate() {
        guard let date = selectDate else { return }
        calendar.deselect(date)
    }
    
}

// MARK:- FS Calendar DataSource
extension CalendarViewController: FSCalendarDataSource {
    
    /// 특정 날짜 점 표시
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
//        guard let eventDate = dateFormatter.date(from: "2020-10-29") else { return 0 }
        let strDate = dateFormatter.string(from:date)
        let dates1 = PlanDates[0]
        let dates2 = PlanDates[1]
        let dates3 = PlanDates[2]
        
        if dates1.contains(strDate) && dates2.contains(strDate) && dates3.contains(strDate) {
            return 3
        } else if dates1.contains(strDate) && dates2.contains(strDate)  {
            return 2
        } else if dates2.contains(strDate) && dates3.contains(strDate) {
            return 2
        } else if dates1.contains(strDate) && dates3.contains(strDate) {
            return 2
        } else if dates1.contains(strDate) {
            return 1
        } else if dates2.contains(strDate) {
            return 1
        } else if dates3.contains(strDate) {
            return 1
        }
        return 0
    }
    
}

// MARK:- FS Calendar Delegate
extension CalendarViewController: FSCalendarDelegate {
    
    // 날짜 선택
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("날짜 선택")
        print(dateFormatter.string(from: date))
        setUserDailyPlan(date: date)
//        SelectedDate.shared.date = dateFormatter.string(from: date)
        tableView.reloadData()
        selectDate = date
    }
    
    // 날짜 선택 해제
//    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at monthPosition: FSCalendarMonthPosition) {
//        print("날짜 선택 해제")
//        print(dateFormatter.string(from: date))
//    }
    
    // 스와이프
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        print("페이지 넘김")
    }
    
    // 특정 날짜를 선택되지 않게 하기
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        guard let excludeDate = dateFormatter.date(from: "2020-11-25") else { return true }
        
        if date.compare(excludeDate) == .orderedSame {
            return false
        } else {
            return true
        }
    }
    
}

// MARK:- FS Calendar Delegate Appearance
extension CalendarViewController: FSCalendarDelegateAppearance {
    
    // 특정 날짜 색 바꾸기
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        guard let eventDate = dateFormatter.date(from: "2020-11-25") else { return nil }
        
        if date.compare(eventDate) == .orderedSame {
            return .red
        } else {
            return nil
        }
    }
    
    // 점 기본 색상
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        
        let strDate = dateFormatter.string(from: date)
        let dates1 = PlanDates[0]
        let dates2 = PlanDates[1]
        let dates3 = PlanDates[2]
        
        if dates1.contains(strDate) && dates2.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue, UIColor.green]
        } else if dates1.contains(strDate) && dates2.contains(strDate)  {
            return [UIColor.red ,UIColor.blue]
        } else if dates2.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue]
        } else if dates1.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue]
        } else if dates1.contains(strDate) {
            return [UIColor.blue]
        } else if dates2.contains(strDate) {
            return [UIColor.blue]
        } else if dates3.contains(strDate) {
            return [UIColor.blue]
        }
        return [UIColor.clear]
    }
    
    // 점 선택 색상
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventSelectionColorsFor date: Date) -> [UIColor]? {
        let strDate = dateFormatter.string(from: date)
        let dates1 = PlanDates[0]
        let dates2 = PlanDates[1]
        let dates3 = PlanDates[2]

        if dates1.contains(strDate) && dates2.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue, UIColor.green]
        } else if dates1.contains(strDate) && dates2.contains(strDate)  {
            return [UIColor.red ,UIColor.blue]
        } else if dates2.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue]
        } else if dates1.contains(strDate) && dates3.contains(strDate) {
            return [UIColor.red ,UIColor.blue]
        } else if dates1.contains(strDate) {
            return [UIColor.blue]
        } else if dates2.contains(strDate) {
            return [UIColor.blue]
        } else if dates3.contains(strDate) {
            return [UIColor.blue]
        }
        return [UIColor.clear]
    }
    
}

// MARK:- Table View DataSource
extension CalendarViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userDailyPlan.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "calendarTableViewCell", for: indexPath) as? CalendarTableViewCell else { return UITableViewCell() }
        // 플랜이름
        cell.planTitleLabel.text = userDailyPlan[indexPath.row].planName
        // 플랜시간
        let timeString = userDailyPlan[indexPath.row].setTime
        let endIdx: String.Index = timeString.index(timeString.startIndex, offsetBy: 4)
        cell.timeLabel.text = String(timeString[...endIdx])
        // 플랜 인증 횟수
        cell.dayLabel.text = "\(userDailyPlan[indexPath.row].nowAuthNum) 일째"
        // 플랜 성공 여부
        let status = checkPlanProgress(status: userDailyPlan[indexPath.row].planProgress)
        cell.successLabel.text = status
        // 플랜 성공 여부 뷰 색상
        let statusColor = checkSuccessColor(status: userDailyPlan[indexPath.row].planProgress)
        cell.successLabelView.backgroundColor = statusColor
        // 플랜 뷰 색상
        let planColor = checkPlanColor(type: userDailyPlan[indexPath.row].needAuthNum)
        cell.planColorBarView.backgroundColor = UIColor(named: planColor)
        cell.dayLabelView.backgroundColor = UIColor(named: planColor)
        // 셀 태그에 플랜로그아이디 삽입
        cell.tag = userDailyPlan[indexPath.row].planLogID
        return cell
    }
    
    // 편집모드로 들어가 테이블뷰 행을 삭제 가능하도록 하는 메서드
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    // 테이블뷰가 편집모드일때 동작을 정의하는 메서드
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let planLogID = tableView.cellForRow(at: indexPath)?.tag else { return }
            print("셀 삭제 플랜로그아이디 : \(planLogID)")
            deletePlan(planID: planLogID)
        }
    }
    
}

// MARK:- Table View Delegate
extension CalendarViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    
}
