'''
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Button


class InteractivePointSelector:
    def __init__(self, image_path):
        self.image_path = image_path
        self.points = []

        # 创建图形和轴
        self.fig, self.ax = plt.subplots()
        self.ax.imshow(plt.imread(self.image_path))
        self.ax.set_title('Click on the image (up to 4 points)')

        # 设置确认和取消按钮
        self.confirm_button_ax = plt.axes([0.8, 0.01, 0.1, 0.05])
        self.cancel_button_ax = plt.axes([0.6, 0.01, 0.1, 0.05])
        self.confirm_button = Button(self.confirm_button_ax, 'Confirm')
        self.cancel_button = Button(self.cancel_button_ax, 'Cancel')

        # 按钮回调
        self.confirm_button.on_clicked(self.confirm)
        self.cancel_button.on_clicked(self.cancel)

        # 连接点击事件
        self.cid = self.fig.canvas.mpl_connect('button_press_event', self.onclick)

        # 强制进入阻塞模式，等待用户操作
        self.run()

    def run(self):
        while plt.fignum_exists(self.fig.number):  # 检查窗口是否仍然存在
            plt.pause(0.1)  # 暂停一小段时间，确保窗口保持响应

    def onclick(self, event):
        if event.inaxes is self.ax:  # 确保点击在图像区域
            if len(self.points) < 4:
                x, y = round(event.xdata), round(event.ydata)
                if x is not None and y is not None:
                    # 添加点并绘制半透明圆点
                    circle = plt.Circle((x, y), 20, color='red', alpha=0.5)
                    self.ax.add_patch(circle)
                    self.points.append([x, y])
                    plt.draw()

    def cancel(self, event):
        if self.points:
            # 移除最后一个点
            self.points.pop()
            self.ax.clear()
            self.ax.imshow(plt.imread(self.image_path))  # 重新显示图像
            for x, y in self.points:
                circle = plt.Circle((x, y), 20, color='red', alpha=0.5)
                self.ax.add_patch(circle)
            plt.draw()

    def confirm(self, event):
        plt.close(self.fig)
'''



import matplotlib.pyplot as plt
import numpy as np
from matplotlib.widgets import Button


class InteractivePointSelector:
    def __init__(self, image_path):
        self.image_path = image_path
        self.points = {"positive": [], "negative": []}
        self.selected_object_id = None
        self.mode = None  # To track whether selecting positive or negative points

        # 创建图形和轴
        self.fig = plt.figure(figsize=(6, 8))
        self.ax = plt.axes([0.1, 0.5, 0.8, 0.45])
        self.ax.imshow(plt.imread(self.image_path))
        self.ax.set_title('Click on the image (up to 4 points)')

        # Object ID buttons
        self.object_buttons = []
        for i in range(4):
            ax_button = plt.axes([0.12 + i * 0.2, 0.4, 0.1, 0.05])
            button = Button(ax_button, str(i + 1))
            button.on_clicked(self.select_object(i + 1))
            self.object_buttons.append(button)

        # Positive and Negative buttons
        self.positive_button_ax = plt.axes([0.15, 0.3, 0.25, 0.05])
        self.negative_button_ax = plt.axes([0.55, 0.3, 0.25, 0.05])
        self.positive_button = Button(self.positive_button_ax, 'Positive points')
        self.negative_button = Button(self.negative_button_ax, 'Negative points')

        # Confirm and cancel buttons for Positive and Negative Points
        self.confirm_button_ax_pos = plt.axes([0.15, 0.22, 0.1, 0.05])
        self.cancel_button_ax_pos = plt.axes([0.30, 0.22, 0.1, 0.05])
        self.confirm_button_pos = Button(self.confirm_button_ax_pos, 'Confirm')
        self.cancel_button_pos = Button(self.cancel_button_ax_pos, 'Cancel')

        self.confirm_button_ax_neg = plt.axes([0.55, 0.22, 0.1, 0.05])
        self.cancel_button_ax_neg = plt.axes([0.7, 0.22, 0.1, 0.05])
        self.confirm_button_neg = Button(self.confirm_button_ax_neg, 'Confirm')
        self.cancel_button_neg = Button(self.cancel_button_ax_neg, 'Cancel')

        # Finish button
        self.finish_button_ax = plt.axes([0.35, 0.1, 0.3, 0.05])
        self.finish_button = Button(self.finish_button_ax, 'Operate Finished')

        # 按钮回调
        self.positive_button.on_clicked(self.select_positive_points)
        self.negative_button.on_clicked(self.select_negative_points)
        self.confirm_button_pos.on_clicked(self.confirm_points('positive'))
        self.cancel_button_pos.on_clicked(self.cancel_points('positive'))
        self.confirm_button_neg.on_clicked(self.confirm_points('negative'))
        self.cancel_button_neg.on_clicked(self.cancel_points('negative'))
        self.finish_button.on_clicked(self.finish_operation)

        # 连接点击事件
        self.cid = self.fig.canvas.mpl_connect('button_press_event', self.onclick)

        # 强制进入阻塞模式，等待用户操作
        self.run()

    def run(self):
        while plt.fignum_exists(self.fig.number):  # 检查窗口是否仍然存在
            plt.pause(0.1)  # 暂停一小段时间，确保窗口保持响应

    def select_object(self, object_id):
        def inner(event):
            self.selected_object_id = object_id
            # Change the color of the selected button to indicate selection
            for btn in self.object_buttons:
                btn.color = 'lightgray'  # Reset all buttons to original color
            self.object_buttons[object_id - 1].color = 'blue'
            plt.draw()
        return inner

    def select_positive_points(self, event):
        if self.selected_object_id is not None:
            self.mode = 'positive'
            self.positive_button.color = 'blue'  # Indicate active mode
            self.negative_button.color = 'lightgray'
            plt.draw()

    def select_negative_points(self, event):
        if self.selected_object_id is not None:
            self.mode = 'negative'
            self.positive_button.color = 'lightgray'
            self.negative_button.color = 'blue'  # Indicate active mode
            plt.draw()

    def onclick(self, event):
        if event.inaxes is self.ax and self.mode in ['positive', 'negative']:  # 确保点击在图像区域
            if len(self.points[self.mode]) < 4:
                x, y = round(event.xdata), round(event.ydata)
                if x is not None and y is not None:
                    # 添加点并绘制半透明圆点
                    if self.mode == 'positive':
                        circle = plt.Circle((x, y), 10, color='red', alpha=0.5)
                    else:
                        circle = plt.Circle((x, y), 10, color='green', alpha=0.5)
                    self.ax.add_patch(circle)
                    self.points[self.mode].append([x, y])
                    plt.draw()

    def confirm_points(self, mode):
        def inner(event):
            if mode == 'positive':
                self.positive_button.color = 'blue'  # Reset after confirm
            elif mode == 'negative':
                self.negative_button.color = 'blue'
            plt.draw()
        return inner

    def cancel_points(self, mode):
        def inner(event):
            if self.points[mode]:
                # 移除最后一个点
                self.points[mode].pop()
                self.ax.clear()
                self.ax.imshow(plt.imread(self.image_path))  # 重新显示图像
                for m in ['positive', 'negative']:
                    for x, y in self.points[m]:
                        circle = plt.Circle((x, y), 20, color='red', alpha=0.5)
                        self.ax.add_patch(circle)
                plt.draw()
        return inner

    def finish_operation(self, event):
        plt.close(self.fig)




if __name__ == '__main__':
# 使用示例
    selector = InteractivePointSelector('./images/truck.jpg')
    print(selector.points)
    print(type(selector.points))
    p_points = selector.points['positive']
    lbs = []
    for length in range(len(p_points)):
        lbs.append(1)
    print(p_points)
    print(type(p_points))
    n_points = selector.points['negative']
    for length in range(len(n_points)):
        lbs.append(-1)
    print(lbs)

    points = p_points + n_points
    print(points)




