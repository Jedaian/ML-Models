from PyQt6 import QtWidgets, QtCore
import pandas as pd
import os

class SentencePicker(QtWidgets.QWidget):
    def __init__(self, input_file, output_file, comparison_file, resume_file):
        super().__init__()

        self.input_file = input_file
        self.output_file = output_file
        self.comparison_file = pd.read_csv(comparison_file)['sentence'].tolist()
        self.resume_file = resume_file

        self.data = pd.read_csv(self.input_file)

        if os.path.exists(self.output_file):
            self.picked_sentences = pd.read_csv(self.output_file)['sentence'].tolist()
        else:
            self.picked_sentences = []

        if os.path.exists(self.resume_file):
            with open(self.resume_file, 'r') as file:
                self.index = int(file.read())
        else:
            self.index = 0

        self.find_next_valid_sentence()

        self.initUI()

    def initUI(self):
        sentence = f"{self.index+1}. {self.data.at[self.index, 'sentence']}"
        self.sentence_label = QtWidgets.QLabel(sentence)
        self.sentence_label.setWordWrap(True)
        self.picked_counter_label = QtWidgets.QLabel(self.get_picked_counter_text())
        self.skip_button = QtWidgets.QPushButton("Skip")
        self.add_button = QtWidgets.QPushButton("Add")
        self.exit_button = QtWidgets.QPushButton("Exit")

        self.layout = QtWidgets.QVBoxLayout()
        self.layout.addWidget(self.sentence_label)
        self.layout.addWidget(self.picked_counter_label)
        self.layout.addWidget(self.skip_button)
        self.layout.addWidget(self.add_button)
        self.layout.addWidget(self.exit_button)
        self.setLayout(self.layout)

        self.skip_button.clicked.connect(self.skip_sentence)
        self.add_button.clicked.connect(self.add_sentence)
        self.exit_button.clicked.connect(QtWidgets.QApplication.instance().quit)

    def get_picked_counter_text(self):
        picked_count = len(self.picked_sentences)
        total_count = 50
        return f"Picked: {picked_count} / {total_count}"

    def update_sentence(self):
        sentence = f"{self.index+1}. {self.data.at[self.index, 'sentence']}"
        self.sentence_label.setText(sentence)
        self.picked_counter_label.setText(self.get_picked_counter_text())

    def save(self):
        pd.DataFrame(self.picked_sentences, columns=['sentence']).to_csv(self.output_file, index=False)
        with open(self.resume_file, 'w') as file:
            file.write(str(self.index))

    def skip_sentence(self):
        if self.index < len(self.data) - 1:
            self.index += 1
            self.find_next_valid_sentence()
            self.update_sentence()
            self.save()
        else:
            self.save()
            QtWidgets.QMessageBox.information(self, "Information", "All sentences have been processed.")
            self.close()

    def add_sentence(self):
        sentence = self.data.at[self.index, 'sentence']
        if len(self.picked_sentences) < 50:
            self.picked_sentences.append(sentence)
            self.skip_sentence()
            if len(self.picked_sentences) >= 50:
                self.save()
                QtWidgets.QMessageBox.information(self, "Information", "Maximum number of picked sentences (2800) has been reached.")
                self.close()
        else:
            QtWidgets.QMessageBox.information(self, "Information", "The maximum limit of picked sentences has been reached.")

    def keyPressEvent(self, event):
        if event.key() == QtCore.Qt.Key.Key_Enter or event.key() == QtCore.Qt.Key.Key_Return:
            if self.skip_button.hasFocus():
                self.skip_sentence()
            elif self.add_button.hasFocus():
                self.add_sentence()
            elif self.exit_button.hasFocus():
                QtWidgets.QApplication.instance().quit()

    def find_next_valid_sentence(self):
        while self.index < len(self.data):
            sentence = self.data.at[self.index, 'sentence']
            if sentence not in self.comparison_file and sentence not in self.picked_sentences:
                return
            self.index += 1

def main():
    app = QtWidgets.QApplication([])
    picker = SentencePicker('/Users/jedai/Desktop/Python/testing/reddit.csv', 
                            '/Users/jedai/Desktop/Python/testing/slang100.csv', 
                            '/Users/jedai/Desktop/Python/testing/mergedData.csv', 
                            '/Users/jedai/Desktop/Python/testing/resume2.txt')
    picker.show()
    app.exec()

if __name__ == '__main__':
    main()
