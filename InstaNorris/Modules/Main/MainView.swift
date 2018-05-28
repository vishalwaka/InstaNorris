//
//  MainView.swift
//  InstaNorris
//
//  Created by Aline Borges on 27/04/18.
//  Copyright © 2018 Aline Borges. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Swinject

class MainView: UIViewController {
    
    var viewModel: MainViewModel!
    let repository: NorrisRepository
    let localStorage: LocalStorage

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: HeaderView!
    @IBOutlet weak var searchContainer: UIView!
    let searchView: SearchView
    
    init(searchView: SearchView, repository: NorrisRepository, localStorage: LocalStorage) {
        self.repository = repository
        self.searchView = searchView
        self.localStorage = localStorage
        super.init(nibName: String(describing: MainView.self), bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureViews()
        self.setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.setupBindings()
    }
    
}

extension MainView {
    
    func setupViewModel() {
        self.viewModel = MainViewModel(
            input: (search: self.headerView.rx.search,
                  searchTap: self.headerView.rx.searchTap.asSignal(),
                  categorySelected: self.searchView.categorySelected),
            repositories: (repository: self.repository,
                           localStorage: localStorage))
    }
    
    func configureViews() {
        self.tableView.contentInset.top = self.headerView.maxHeight
        self.tableView.register(cellType: FactCell.self)
        self.tableView.estimatedRowHeight = 200
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.configureSearchView()
        self.searchView.delegate = self
    }
    
    func setupBindings() {
    
        self.viewModel.results
            .bind(to: tableView.rx
                .items(cellIdentifier: "FactCell",
                       cellType: FactCell.self)) { _, element, cell in
                        cell.bind(element)
            }.disposed(by: rx.disposeBag)
        
        self.tableView.rx.contentOffset
            .map { $0.y }
            .map { ($0 + self.headerView.maxHeight) / (self.headerView.minHeight + self.headerView.maxHeight) }
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: self.headerView.rx.fractionComplete)
            .disposed(by: rx.disposeBag)
        
        self.headerView.searchTextField.rx.controlEvent(.editingDidBegin)
            .subscribe(onNext: {
                self.searchContainer.isHidden = false
            }).disposed(by: rx.disposeBag)
       
        self.viewModel.searchHidden
            .bind(to: self.searchContainer.rx.isHidden)
            .disposed(by: rx.disposeBag)
        
        self.headerView.rx.searchTap.bind {
            self.view.endEditing(true)
        }.disposed(by: rx.disposeBag)
        
    }
    
    func configureSearchView() {
        self.searchContainer.addSubview(searchView.view)
        self.addChildViewController(self.searchView)
        self.searchView.view.prepareForConstraints()
        self.searchView.view.pinEdgesToSuperview()
    }
}

extension MainView: SearchDelegate {
    func dismiss() {
        self.searchContainer.isHidden = true
    }
    
    func searchCategory(_ category: String) {
        //self.viewModel.search.onNext(category)
    }
}
