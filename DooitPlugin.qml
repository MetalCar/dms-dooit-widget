import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    layerNamespacePlugin: "dooit-plugin"

    property string scriptPath: filePath(Qt.resolvedUrl("scripts/dooit-collector.py"))

    property string icon: "✅ "
    property string text: ""
    property string debugText: ""
    property string cssClass: "dooit"

    property var todoHeight: 25 

    ListModel { id: allToDosModel }

    function setModel(model, arr) {
        model.clear()
        if (!arr) return
        for (let i = 0; i < arr.length; i++) {
            model.append({ text: String(arr[i]) })
        }
    }

    function filePath(url) {
        return String(url).replace(/^file:\/\//, "")
    }

    function showToast(msg, title = "Title") {
        ToastService.showInfo(title, msg)
    }

    function refresh() {
        proc.running = false
        proc.command = ["python3", scriptPath]
        proc.running = true
    }

    function showToDo(todo)
    {
        const [description, pending, due] = todo.split(",")
        return (pending == "true" ? "❌" : "✅️") + " " + description + " " + due
    }

    function getHeight(todos) 
    {
        const todoCount = parseInt(todos.count)
        return root.todoHeight * todoCount
    }

    Timer {
        interval: 60 * 1000 // every minute
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    Process {
        id: proc
        stdout: StdioCollector {
            id: out
            onStreamFinished: () => {
                try {
                    const obj = JSON.parse(text.trim())
                    root.text = icon + (obj.todoCount ?? 0)

                    setModel(allToDosModel, obj.todos)
                } catch(e) {
                    showToast("PARSE ERROR: " + String(e))
                    root.text = icon + 0
                    root.debugText = "JSON parse error:\n" + text
                }
            }
        }

        stderr: StdioCollector {
            id: outErr
            onStreamFinished: () => {
                if (text && text.trim().length > 0) {
                    root.debugText = "Script error:\n" + text
                    root.text = icon + 0
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutColumn
            headerText: "Todos"
            detailsText: root.debugText
            showCloseButton: true

            Item {
                width: parent.width
                implicitHeight: getHeight(allToDosModel) + 50
                DankListView {
                    anchors.fill: parent
                    model: allToDosModel
                    spacing: 6

                    delegate: Item {
                        width: ListView.view.width
                        height: root.todoHeight

                        StyledText {
                            id: label
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: showToDo(model.text)
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }


    horizontalBarPill: Component {
        Row {
            StyledText {
                text: root.text
                color: Theme.primary
            }
        }       
    }

    popoutWidth: 620
}