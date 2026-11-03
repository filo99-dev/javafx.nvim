-- JavaFX components usable as FXML tags, grouped by package.
local PACKAGES = {
  ["javafx.scene.control"] = {
    "Accordion", "Button", "ButtonBar", "CheckBox", "CheckMenuItem", "ChoiceBox",
    "ColorPicker", "ComboBox", "ContextMenu", "CustomMenuItem", "DatePicker",
    "DialogPane", "Hyperlink", "Label", "ListView", "Menu", "MenuBar", "MenuButton",
    "MenuItem", "Pagination", "PasswordField", "ProgressBar", "ProgressIndicator",
    "RadioButton", "RadioMenuItem", "ScrollBar", "ScrollPane", "Separator",
    "SeparatorMenuItem", "Slider", "Spinner", "SplitMenuButton", "SplitPane", "Tab",
    "TabPane", "TableColumn", "TableView", "TextArea", "TextField", "TitledPane",
    "ToggleButton", "ToggleGroup", "ToolBar", "Tooltip", "TreeItem", "TreeTableColumn",
    "TreeTableView", "TreeView",
  },
  ["javafx.scene.layout"] = {
    "AnchorPane", "BorderPane", "ColumnConstraints", "FlowPane", "GridPane", "HBox",
    "Pane", "Region", "RowConstraints", "StackPane", "TilePane", "VBox",
  },
  ["javafx.scene.shape"] = {
    "Arc", "Circle", "CubicCurve", "Ellipse", "Line", "Path", "Polygon", "Polyline",
    "QuadCurve", "Rectangle", "SVGPath",
  },
  ["javafx.scene.text"] = { "Font", "Text", "TextFlow" },
  ["javafx.scene.image"] = { "Image", "ImageView" },
  ["javafx.scene.canvas"] = { "Canvas" },
  ["javafx.scene.web"] = { "WebView" },
  ["javafx.scene.media"] = { "MediaView" },
  ["javafx.scene"] = { "Group", "Scene", "SubScene" },
  ["javafx.scene.chart"] = {
    "AreaChart", "BarChart", "BubbleChart", "CategoryAxis", "LineChart", "NumberAxis",
    "PieChart", "ScatterChart", "StackedAreaChart", "StackedBarChart",
  },
  ["javafx.scene.effect"] = { "DropShadow", "GaussianBlur", "Glow", "InnerShadow", "Reflection" },
  ["javafx.scene.paint"] = { "Color" },
  ["javafx.geometry"] = { "Insets" },
}

local list = {}
for pkg, names in pairs(PACKAGES) do
  for _, name in ipairs(names) do
    list[#list + 1] = { name = name, pkg = pkg }
  end
end
table.sort(list, function(a, b) return a.name < b.name end)

return list
