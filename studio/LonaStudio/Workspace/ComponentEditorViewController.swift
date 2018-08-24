//
//  ComponentEditorViewController.swift
//  LonaStudio
//
//  Created by Devin Abbott on 8/24/18.
//  Copyright © 2018 Devin Abbott. All rights reserved.
//

import AppKit
import Foundation

class ComponentEditorViewController: NSSplitViewController {
    private let splitViewResorationIdentifier = "tech.lona.restorationId:componentEditorController"
    private let layerEditorViewResorationIdentifier = "tech.lona.restorationId:layerEditorController"

    // MARK: Lifecycle

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpViews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Public

    public var component: CSComponent? = nil { didSet { update() } }
    public var canvasPanningEnabled: Bool {
        get { return canvasCollectionView.panningEnabled }
        set { canvasCollectionView.panningEnabled = newValue }
    }

    public func addLayer(_ layer: CSLayer) {
        layerList.addLayer(layer: layer)
    }

    func zoomToActualSize() {
        canvasCollectionView.zoom(to: 1)
    }

    func zoomIn() {
        canvasCollectionView.zoomIn()
    }

    func zoomOut() {
        canvasCollectionView.zoomOut()
    }

    // MARK: Private

    private lazy var utilitiesView = UtilitiesView()
    private lazy var utilitiesViewController: NSViewController = {
        return NSViewController(view: utilitiesView)
    }()

    private lazy var canvasCollectionView = CanvasCollectionView(frame: .zero)
    private lazy var canvasCollectionViewController: NSViewController = {
        return NSViewController(view: canvasCollectionView)
    }()

    private lazy var layerList = LayerList()
    private lazy var layerListViewController: NSViewController = {
        return NSViewController(view: layerList)
    }()

    private lazy var layerEditorController: NSViewController = {
        let vc = NSSplitViewController(nibName: nil, bundle: nil)

        vc.splitView.isVertical = true
        vc.splitView.dividerStyle = .thin
        vc.splitView.autosaveName = NSSplitView.AutosaveName(rawValue: layerEditorViewResorationIdentifier)
        vc.splitView.identifier = NSUserInterfaceItemIdentifier(rawValue: layerEditorViewResorationIdentifier)

        vc.minimumThicknessForInlineSidebars = 120

        let leftItem = NSSplitViewItem(contentListWithViewController: layerListViewController)
        leftItem.canCollapse = false
        //        leftItem.minimumThickness = 120
        vc.addSplitViewItem(leftItem)

        let mainItem = NSSplitViewItem(viewController: canvasCollectionViewController)
        mainItem.minimumThickness = 300
        vc.addSplitViewItem(mainItem)

        return vc
    }()

    private func setUpViews() {
        setUpUtilities()

        layerList.fillColor = .white

        let tabs = SegmentedControlField(
            frame: NSRect(x: 0, y: 0, width: 500, height: 24),
            values: [
                UtilitiesView.Tab.devices.rawValue,
                UtilitiesView.Tab.parameters.rawValue,
                UtilitiesView.Tab.logic.rawValue,
                UtilitiesView.Tab.examples.rawValue,
                UtilitiesView.Tab.details.rawValue
            ])
        tabs.segmentWidth = 97
        tabs.useYogaLayout = true
        tabs.segmentStyle = .roundRect
        tabs.onChange = { value in
            guard let tab = UtilitiesView.Tab(rawValue: value) else { return }
            self.utilitiesView.currentTab = tab
        }
        tabs.value = UtilitiesView.Tab.devices.rawValue

        let splitView = SectionSplitter()
        splitView.addSubviewToDivider(tabs)

        splitView.isVertical = false
        splitView.dividerStyle = .thin
        splitView.autosaveName = NSSplitView.AutosaveName(rawValue: splitViewResorationIdentifier)
        splitView.identifier = NSUserInterfaceItemIdentifier(rawValue: splitViewResorationIdentifier)

        self.splitView = splitView
    }

    func setUpUtilities() {
        utilitiesView.onChangeMetadata = { value in
            self.component?.metadata = value
        }

        utilitiesView.onChangeCanvasList = { value in
            self.component?.canvas = value
        }

        utilitiesView.onChangeCanvasLayout = { value in
            self.component?.canvasLayoutAxis = value
        }

        utilitiesView.onChangeParameterList = { value in
            self.component?.parameters = value
            self.utilitiesView.reloadData()

            let componentParameters = value.filter({ $0.type == CSComponentType })
            let componentParameterNames = componentParameters.map({ $0.name })
            ComponentMenu.shared?.update(componentParameterNames: componentParameterNames)
        }

        utilitiesView.onChangeCaseList = { value in
            self.component?.cases = value
        }

        utilitiesView.onChangeLogicList = { value in
            self.component?.logic = value
        }
    }

    private func setUpLayout() {
        minimumThicknessForInlineSidebars = 180

        let mainItem = NSSplitViewItem(viewController: layerEditorController)
        mainItem.minimumThickness = 300
        addSplitViewItem(mainItem)

        let bottomItem = NSSplitViewItem(viewController: utilitiesViewController)
        bottomItem.canCollapse = false
        bottomItem.minimumThickness = 120
        addSplitViewItem(bottomItem)
    }

    private func update() {
        utilitiesView.component = component
        layerList.component = component

        guard let component = component else { return }

        let options = CanvasCollectionOptions(
            layout: component.canvasLayoutAxis,
            component: component,
            selected: nil,
            onSelectLayer: { _ in }
        )

        canvasCollectionView.update(options: options)
    }
}
