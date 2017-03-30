//
//  RINGTableViewController.swift
//  RING
//
//  Created by chang ming-jui on 2017/3/30.
//  Copyright © 2017年 chang ming-jui. All rights reserved.
//

import UIKit

class RINGTableViewController: UITableViewController {

   
        var alarmDelegate: AlarmApplicationDelegate = AppDelegate()
        var alarmScheduler: AlarmSchedulerDelegate = Scheduler()
        var alarmModel: Alarms = Alarms()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            tableView.allowsSelectionDuringEditing = true
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            alarmModel = Alarms()
            tableView.reloadData()
            //dynamically append the edit button
            if alarmModel.count != 0 {
                self.navigationItem.leftBarButtonItem = editButtonItem
            }
            else {
                self.navigationItem.leftBarButtonItem = nil
            }
            //unschedule all the notifications, faster than calling the cancelAllNotifications func
    //        UIApplication.shared.scheduledLocalNotifications = nil
            
            let cells = tableView.visibleCells
            if !cells.isEmpty {
                for i in 0..<cells.count {
                    if alarmModel.alarms[i].enabled {
                        (cells[i].accessoryView as! UISwitch).setOn(true, animated: false)
                        cells[i].backgroundColor = UIColor.white
                        cells[i].textLabel?.alpha = 1.0
                        cells[i].detailTextLabel?.alpha = 1.0
                    }
                    else {
                        (cells[i].accessoryView as! UISwitch).setOn(false, animated: false)
                        cells[i].backgroundColor = UIColor.groupTableViewBackground
                        cells[i].textLabel?.alpha = 0.5
                        cells[i].detailTextLabel?.alpha = 0.5
                    }
                }
            }
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
        }
        
        // MARK: - Table view data source
        
        override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 90
        }
        
        override func numberOfSections(in tableView: UITableView) -> Int {
            // Return the number of sections.
            return 1
        }
        
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            // Return the number of rows in the section.
            if alarmModel.count == 0 {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.none
            }
            else {
                tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            }
            return alarmModel.count
        }
        
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if isEditing {
                performSegue(withIdentifier: Id.editSegueIdentifier, sender: SegueInfo(curCellIndex: indexPath.row, isEditMode: true, label: alarmModel.alarms[indexPath.row].label, mediaLabel: alarmModel.alarms[indexPath.row].mediaLabel, mediaID: alarmModel.alarms[indexPath.row].mediaID, repeatWeekdays: alarmModel.alarms[indexPath.row].repeatWeekdays, enabled: alarmModel.alarms[indexPath.row].enabled))
            }
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            var cell = tableView.dequeueReusableCell(withIdentifier: Id.alarmCellIdentifier)
            if (cell == nil) {
                cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: Id.alarmCellIdentifier)
            }
            //cell text
            cell!.selectionStyle = .none
            cell!.tag = indexPath.row
            let alarm: Alarm = alarmModel.alarms[indexPath.row]
            let amAttr: [String : Any] = [NSFontAttributeName : UIFont.systemFont(ofSize: 20.0)]
            let str = NSMutableAttributedString(string: alarm.formattedTime, attributes: amAttr)
            let timeAttr: [String : Any] = [NSFontAttributeName : UIFont.systemFont(ofSize: 45.0)]
            str.addAttributes(timeAttr, range: NSMakeRange(0, str.length-2))
            cell!.textLabel?.attributedText = str
            cell!.detailTextLabel?.text = alarm.label
            //append switch button
            let sw = UISwitch(frame: CGRect())
            sw.transform = CGAffineTransform(scaleX: 0.9, y: 0.9);
            
            //tag is used to indicate which row had been touched
            sw.tag = indexPath.row
            sw.addTarget(self, action: #selector(RINGTableViewController.switchTapped(_:)), for: UIControlEvents.touchUpInside)
            if alarm.enabled {
                sw.setOn(true, animated: false)
            }
            cell!.accessoryView = sw
            
            //delete empty seperator line
            tableView.tableFooterView = UIView(frame: CGRect.zero)
            
            return cell!
        }
        
        @IBAction func switchTapped(_ sender: UISwitch) {
            let index = sender.tag
            alarmModel.alarms[index].enabled = sender.isOn
            if sender.isOn {
                print("switch on")
                sender.superview?.backgroundColor = UIColor.white
                alarmScheduler.setNotificationWithDate(alarmModel.alarms[index].date, onWeekdaysForNotify: alarmModel.alarms[index].repeatWeekdays, snoozeEnabled: alarmModel.alarms[index].snoozeEnabled, onSnooze: false, soundName: alarmModel.alarms[index].mediaLabel, index: index)
                let cells = tableView.visibleCells
                if !cells.isEmpty {
                    cells[index].textLabel?.alpha = 1.0
                    cells[index].detailTextLabel?.alpha = 1.0
                }
            }
            else {
                print("switch off")
                sender.superview?.backgroundColor = UIColor.groupTableViewBackground
                let cells = tableView.visibleCells
                if !cells.isEmpty {
                    cells[index].textLabel?.alpha = 0.5
                    cells[index].detailTextLabel?.alpha = 0.5
                }
                alarmScheduler.reSchedule()
            }
        }
        
        //不顯示edit
        // Override to support editing the table view.
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let index = indexPath.row
                alarmModel.alarms.remove(at: index)
                let cells = tableView.visibleCells
                for cell in cells {
                    let sw = cell.accessoryView as! UISwitch
                    //adjust saved index when row deleted
                    if sw.tag > index {
                        sw.tag -= 1
                    }
                }
                if alarmModel.count == 0 {
                    self.navigationItem.leftBarButtonItem = nil
                }
                
                // Delete the row from the data source
                tableView.deleteRows(at: [indexPath], with: .fade)
                alarmScheduler.reSchedule()
            }
        }
        
        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            let dist = segue.destination as! UINavigationController
            let addEditController = dist.topViewController as! AlarmAddEditViewController
            if segue.identifier == Id.addSegueIdentifier {
                addEditController.navigationItem.title = "Add Ring"
                addEditController.segueInfo = SegueInfo(curCellIndex: alarmModel.count, isEditMode: false, label: "Ring", mediaLabel: "bell", mediaID: "", repeatWeekdays: [], enabled: false)
            }
            else if segue.identifier == Id.editSegueIdentifier {
                addEditController.navigationItem.title = "Edit Ring"
                addEditController.segueInfo = sender as! SegueInfo
            }
        }
        
        @IBAction func unwindFromAddEditAlarmView(_ segue: UIStoryboardSegue) {
            isEditing = false
        }
        
    }
    
    
    
    
    
    
    
    
    
    
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
 
*/

