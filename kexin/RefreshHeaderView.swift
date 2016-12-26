//
//  RefreshHeaderView.swift
//  RefreshExample
//
//  Created by SunSet on 14-6-24.
//  Copyright (c) 2014 zhaokaiyuan. All rights reserved.
//

import UIKit
class RefreshHeaderView: RefreshBaseView {
    class func footer()->RefreshHeaderView{
        let footer:RefreshHeaderView  = RefreshHeaderView(frame: CGRect(x:0, y:0,  width: UIScreen.main.bounds.width,  height: CGFloat(RefreshViewHeight)))
        return footer
    }
    
    // 最后的更新时间
    var lastUpdateTime:Date = Date(){
    willSet{
        
    }
    didSet{
        UserDefaults.standard.set(lastUpdateTime, forKey: RefreshHeaderTimeKey as String)
        UserDefaults.standard.synchronize()
        self.updateTimeLabel()
    }
    }
    
    // 最后的更新时间lable
    var lastUpdateTimeLabel:UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        lastUpdateTimeLabel = UILabel()
        lastUpdateTimeLabel.autoresizingMask = UIViewAutoresizing.flexibleWidth
        lastUpdateTimeLabel.font = UIFont.boldSystemFont(ofSize: 12)
        lastUpdateTimeLabel.textColor = RefreshLabelTextColor
        lastUpdateTimeLabel.backgroundColor = UIColor.clear
        lastUpdateTimeLabel.textAlignment = NSTextAlignment.center
        self.addSubview(lastUpdateTimeLabel);
        
        if  (UserDefaults.standard.object(forKey: RefreshHeaderTimeKey as String) == nil)  {
            self.lastUpdateTime = Date()
        } else {
          self.lastUpdateTime = (UserDefaults.standard.object(forKey: RefreshHeaderTimeKey as String) as! NSDate) as Date
        }
        self.updateTimeLabel()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let statusX:CGFloat = 0
        let statusY:CGFloat = 0
        let statusHeight:CGFloat = self.frame.size.height * 0.5
        let statusWidth:CGFloat = self.frame.size.width
        //状态标签
        self.statusLabel.frame = CGRect(x: statusX, y:statusY, width: statusWidth, height: statusHeight)
        //时间标签
        let lastUpdateY:CGFloat = statusHeight
        let lastUpdateX:CGFloat = 0
        let lastUpdateHeight:CGFloat = statusHeight
        let lastUpdateWidth:CGFloat = statusWidth
        self.lastUpdateTimeLabel.frame = CGRect(x: lastUpdateX, y: lastUpdateY, width: lastUpdateWidth, height: lastUpdateHeight);
    }
    
    override func willMove(toSuperview newSuperview: UIView!) {
        super.willMove(toSuperview: newSuperview)
         // 设置自己的位置和尺寸
        var rect:CGRect = self.frame
        rect.origin.y = -self.frame.size.height
        self.frame = rect
    }
    
    func updateTimeLabel(){
        //更新时间字符串
        let calendar:NSCalendar = NSCalendar.current as NSCalendar
        let unitFlags:NSCalendar.Unit = [NSCalendar.Unit.year , NSCalendar.Unit.month , NSCalendar.Unit.day ,  NSCalendar.Unit.hour , NSCalendar.Unit.minute]
        let cmp1:DateComponents = (calendar.components(unitFlags, from:lastUpdateTime as Date) as NSDateComponents) as DateComponents
        let cmp2:DateComponents = (calendar.components(unitFlags, from: Date() as Date) as NSDateComponents) as DateComponents
        let formatter:DateFormatter = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        var time:String = formatter.string(from: self.lastUpdateTime as Date)
        self.lastUpdateTimeLabel.text = "最后刷新时间:"+time
        
    }
    
    //监听UIScrollView的contentOffset属性
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (!self.isUserInteractionEnabled || self.isHidden){
            return
        }
        if (self.State == RefreshState.refreshing) {
            return
        }
        if RefreshContentOffset.isEqual(to: keyPath!){
            self.adjustStateWithContentOffset()
        }
    }
    
   
    
   
    
    //调整状态
    func adjustStateWithContentOffset()
    {
        let currentOffsetY:CGFloat = self.scrollView.contentOffset.y
        let happenOffsetY:CGFloat = -self.scrollViewOriginalInset.top
        if (currentOffsetY >= happenOffsetY) {
            return
        }
        if self.scrollView.isDragging{
            let normal2pullingOffsetY:CGFloat = happenOffsetY - self.frame.size.height
            if  self.State == RefreshState.normal && currentOffsetY < normal2pullingOffsetY{
                self.State = RefreshState.pulling
            }else if self.State == RefreshState.pulling && currentOffsetY >= normal2pullingOffsetY{
                self.State = RefreshState.normal
            }
            
        } else if self.State == RefreshState.pulling {
            self.State = RefreshState.refreshing
        }
    }
    
    //设置状态
    override  var State:RefreshState {
    willSet {
        if  State == newValue{
            return;
        }
        oldState = State
        setState(newValue)
    }
    didSet{
        switch State{
        case .normal:
            self.statusLabel.text = RefreshHeaderPullToRefresh as String
            if RefreshState.refreshing == oldState {
                self.arrowImage.transform = CGAffineTransform.identity
                self.lastUpdateTime = Date()
                UIView.animate(withDuration: RefreshSlowAnimationDuration, animations: {
                    var contentInset:UIEdgeInsets = self.scrollView.contentInset
                    contentInset.top = self.scrollViewOriginalInset.top
                    self.scrollView.contentInset = contentInset
                    })
                
            }else {
                UIView.animate(withDuration: RefreshSlowAnimationDuration, animations: {
                     self.arrowImage.transform = CGAffineTransform.identity
                    })
            }
            break
        case .pulling:
            self.statusLabel.text = RefreshHeaderReleaseToRefresh as String
            UIView.animate(withDuration: RefreshSlowAnimationDuration, animations: {
                 self.arrowImage.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI ))
                })
            
   
            
            break
        case .refreshing:
            self.statusLabel.text =  RefreshHeaderRefreshing as String;
            
            UIView.animate(withDuration: RefreshSlowAnimationDuration, animations: {
                let top:CGFloat = self.scrollViewOriginalInset.top + self.frame.size.height
                var inset:UIEdgeInsets = self.scrollView.contentInset
                inset.top = top
                self.scrollView.contentInset = inset
                var offset:CGPoint = self.scrollView.contentOffset
                offset.y = -top
                self.scrollView.contentOffset = offset
                })
            break
        default:
            break
            
        }
    }
    }
    
    func addState(_ state:RefreshState){
        self.State = state
    }
}
    
