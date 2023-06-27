from PyQt6 import QtWidgets, QtCore
import pandas as pd
import numpy as np
import os

class SentenceLabeler(QtWidgets.QWidget):
    def __init__(self, input_file, output_file):
        super().__init__()

        self.input_file = input_file
        self.output_file = output_file

        if os.path.exists(self.output_file):
            self.data = pd.read_csv(self.output_file)
        else:
            self.data = pd.read_csv(self.input_file)
            self.data['label'] = np.nan

        self.index = self.find_first_unlabeled()
        sentence = f"{self.index+1}. {self.data.at[self.index, 'sentence']}"
        self.sentence_label = QtWidgets.QLabel(sentence)
        self.sentence_label.setWordWrap(True)
        self.labeled_counter_label = QtWidgets.QLabel(self.get_labeled_counter_text())
        self.label_group = QtWidgets.QButtonGroup()
        self.label0_button = QtWidgets.QRadioButton("Non-slang (0)")
        self.label1_button = QtWidgets.QRadioButton("Slang (1)")
        self.label2_button = QtWidgets.QRadioButton("To be removed (2)")
        self.label_group.addButton(self.label0_button, 0)
        self.label_group.addButton(self.label1_button, 1)
        self.label_group.addButton(self.label2_button, 2)
        self.label_group.setId(self.label0_button, 0)
        self.label_group.setId(self.label1_button, 1)
        self.label_group.setId(self.label2_button, 2)
        self.previous_button = QtWidgets.QPushButton("Previous")
        self.next_button = QtWidgets.QPushButton("Next")
        self.exit_button = QtWidgets.QPushButton("Exit")

        self.layout = QtWidgets.QVBoxLayout()
        self.layout.addWidget(self.sentence_label)
        self.layout.addWidget(self.labeled_counter_label)
        self.layout.addWidget(self.label0_button)
        self.layout.addWidget(self.label1_button)
        self.layout.addWidget(self.label2_button)
        self.layout.addWidget(self.previous_button)
        self.layout.addWidget(self.next_button)
        self.layout.addWidget(self.exit_button)
        self.setLayout(self.layout)

        self.previous_button.clicked.connect(self.previous_sentence)
        self.next_button.clicked.connect(self.next_sentence)
        self.exit_button.clicked.connect(QtWidgets.QApplication.instance().quit)

        self.update_label()

    def find_first_unlabeled(self):
        unlabeled_indices = self.data[self.data['label'].isnull()].index
        return unlabeled_indices.min() if not unlabeled_indices.empty else 0

    def get_labeled_counter_text(self):
        labeled_count = self.data['label'].notnull().sum()
        total_count = len(self.data)
        return f"Labeled: {labeled_count} / {total_count}"

    def save(self):
        self.data.to_csv(self.output_file, index=False)

    def update_sentence(self):
        sentence = f"{self.index+1}. {self.data.at[self.index, 'sentence']}"
        self.sentence_label.setText(sentence)
        self.update_label()
        self.labeled_counter_label.setText(self.get_labeled_counter_text())

    def update_label(self):
        label = self.data.at[self.index, 'label']
        if not np.isnan(label):
            button = self.label_group.button(int(label))
            button.setChecked(True)

    def previous_sentence(self):
        if self.index > 0:
            self.index -= 1
            self.update_sentence()
            self.save()
    
    def next_sentence(self):
        self.data.at[self.index, 'label'] = self.label_group.checkedId()
        if self.index < len(self.data) - 1:
            self.index += 1
            self.update_sentence()
        else:
            self.save()
            QtWidgets.QMessageBox.information(self, "Information", "All sentences have been labeled.")
            self.close()
        self.save()
    
    def keyPressEvent(self, event):
        if event.key() == QtCore.Qt.Key.Key_1:
            self.label0_button.setChecked(True)
            self.next_sentence()
        elif event.key() == QtCore.Qt.Key.Key_2:
            self.label1_button.setChecked(True)
            self.next_sentence()
        elif event.key() == QtCore.Qt.Key.Key_3:
            self.label2_button.setChecked(True)
            self.next_sentence()
        elif event.key() == QtCore.Qt.Key.Key_Enter or event.key() == QtCore.Qt.Key.Key_Return:
            if self.previous_button.hasFocus():
                self.previous_sentence()
            elif self.next_button.hasFocus():
                self.next_sentence()
            elif self.exit_button.hasFocus():
                QtWidgets.QApplication.instance().quit()

def main():
    app = QtWidgets.QApplication([])
    labeler = SentenceLabeler('/Users/jedai/Desktop/Python/testing/10kdata.csv', '/Users/jedai/Desktop/Python/testing/10kdatalabel.csv')
    labeler.show()
    app.exec()

if __name__ == '__main__':
    main()
