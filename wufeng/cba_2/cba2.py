import streamlit as st
import re
import requests
import json
import time
from datetime import datetime
import os
import base64
from material2 import welcome_2,prompt_1,prompt_2,guide,prompt_3,prompt_4

# 设置页面布局模式为宽屏
st.set_page_config(layout="wide")
# 添加整体字号自定义 CSS 样式
st.markdown(
    """
    <style>
    /* 调整整个页面的基础字体大小 */
    html, body, [class*="css"]  {
        font-size: 18px; /* 修改为所需的字号大小 */
    }
    
    /* 可选：调整特定元素的字体大小 */
    .stMarkdown {
        font-size: 18px;
    }
    .stButton button {
        font-size: 18px;
    }
    .stTextInput input {
        font-size: 18px;
    }
    </style>
    """,
    unsafe_allow_html=True,
)
# 添加对话气泡自定义 CSS 样式
st.markdown(
    """
    <style>
    .chat-container {
        font-family: Arial, sans-serif;
        margin: 10px 0;
        padding: 10px;
        border-radius: 10px;
        max-width: 80%;
    }
    .user {
        background-color: #E8F5E9;  /* 用户消息背景色 */
        text-align: left;
        margin-left: 10px;
        margin-right: auto;
    }
    .assistant {
        background-color: #C8E6C9;  /* GPT 消息背景色 */
        text-align: left;
        margin-left: 10px;
        margin-right: auto;
    }
    </style>
    """,
    unsafe_allow_html=True,
)

# 定义检查姓名是否为2或3个汉字的函数
def is_valid_name(name):
    return bool(re.fullmatch(r'^[\u4e00-\u9fa5]{2,3}$', name))
# 定于显示完整对话历史的函数
def display_chat():
    h = 550 # 文本框高度
    with messages_placeholder.container(height=h):
        for message in st.session_state.history[3:]:
            with st.chat_message(message['role']):
                st.markdown(f"""
                            {message['content']}
                            """)
# 定义获取gpts回复和显示对话的函数
def get_response(input_text,file_path):
    if not st.session_state.file_context_added:
        # 加载预定义的文件
        file_content = load_file(file_path[st.session_state.current_question_index])
        if file_content:
            st.session_state.history.append({
                "role": "user",
                "content": prompt[st.session_state.current_question_index]})
            st.session_state.history.append({
                "role": "user",
                "content": f"以下是需要参考的文档内容：\n{file_content}"})
            st.session_state.file_context_added = True  # 防止重复添加
    
    st.session_state.history.append({"role": "user", "content": input_text})# 记录用户输入
    display_chat()
   # model = models[st.session_state.current_question_index]# 一则阅读材料对应一个gpts，此处确定调用的gpts地址
    data = {
        'model': 'gpt-4o-all',# “gpt-3.5-turbo”为测试用，正式测试改为model
        'messages': st.session_state.history,
        'stream': True
    }

    response = requests.post('https://api.gptgod.online/v1/chat/completions', headers=headers, json=data, stream=True)# 发送请求

    #message = ""
    ai_reply = {"role": "assistant", "content": ""}
    st.session_state.history.append(ai_reply)

    messages_placeholder.empty()
    for line in response.iter_lines():# 逐行处理流式返回的响应
        if line:
            decoded_line = line.decode('utf-8')

            if decoded_line == 'data: [DONE]':# API返回'data:[done]'时返回消息结束
                break

            if decoded_line.startswith('data: '):# 解析并获取AI回复内容，添加到ai_reply中
                data_str = decoded_line.replace('data: ', '')
                data_json = json.loads(data_str)
                content = data_json['choices'][0]['delta'].get('content', '')
                #message += f'{content}'
                ai_reply["content"] += f'{content}'

                display_chat()
                time.sleep(0.05)  # 模拟人类打字速度
    display_chat()
    
# 定义导出对话历史文件的函数
def chat2file():
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    file_name = f"{st.session_state.class_name}_{st.session_state.user_name}_{timestamp}.txt"# 用时间戳和学生班级姓名命名对话记录文件
    folder_path = "chat_history"# 保存文件夹
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)
    file_path = os.path.join(folder_path, file_name)
    with open(file_path, 'w', encoding='utf-8') as f:
        for idx, history in enumerate(st.session_state.all_history):
            f.write(f"第{idx + 1}部分的聊天记录:\n")
            for msg in history:
                f.write(f"{msg['role']}: {msg['content']}\n")
            f.write("\n")
    st.session_state.end = True

def load_file(file_path):
   """
   读取并解析预定义的文件内容
   """
   try:
       file_type = file_path.split('.')[-1]
       if file_type == "txt":
            with open(file_path, "r", encoding="utf-8") as f:
                return f.read()
       else:
           return "不支持的文件类型"
   except Exception as e:
       return f"文件加载失败: {e}"  

# 设置标题和欢迎内容
# st.title("阅读小测试")

# 设置调用的gpts编号和中转密钥
# models = ['gpt-4-gizmo-g-It3OK1ksb','gpt-4-gizmo-g-67444cd74bcc819191e2c511b9a897ce']

# 定义阅读材料列表和提示词
reading_material = ["雷雨.pdf","绿海龟的生命旅途.pdf","绿海龟的生命旅途.pdf","绿海龟的生命旅途.pdf"]
file = ["雷雨.txt","绿海龟的生命旅途1.txt","绿海龟的生命旅途2.txt","绿海龟的生命旅途3.txt"]
prompt = [prompt_1,prompt_2,prompt_3,prompt_4]

headers = {
    "Authorization": "Bearer sk-yF53eKUK0CpyVTnxIAXifrkEg2I0Yff18En9GwAfpsDo7luC"
}

# 初始化相关变量
# 阅读材料编号
if "current_question_index" not in st.session_state:
    st.session_state.current_question_index = 0
    st.session_state.all_history = []
# 对话历史
if 'history' not in st.session_state or not st.session_state.history:
    st.session_state.history = []
# 学生班级
if 'class_name' not in st.session_state:
    st.session_state.class_name = ""
# 学生姓名
if 'user_name' not in st.session_state:
    st.session_state.user_name = ""
# 第一次打招呼  
if 'first' not in st.session_state:
    st.session_state.first = True
# 二次确认
if "show_confirmation" not in st.session_state:
    st.session_state.show_confirmation = False
# 文件上传
if 'file_context_added' not in st.session_state:
    st.session_state.file_context_added = False
# 示例材料,练习环节
if 'example' not in st.session_state:
    st.session_state.example = False
# 结束页面
if 'end' not in st.session_state:
    st.session_state.end = False
    
# 显示欢迎界面
if not (st.session_state.class_name and st.session_state.user_name):
    st.markdown("<h1 style='text-align: center;'>💬阅读小测试</h1>", unsafe_allow_html=True,)
    st.info(welcome_2)
    col1, col2 = st.columns([1,1])
    with col1:
        class_name = st.text_input("请在下面输入你的班级")
    with col2:
        user_name = st.text_input("请在下面输入你的姓名")
    
    if st.button("提交"):
        if not class_name:
            st.error("请输入你的班级")
        if not user_name:
            st.error("请输入你的姓名")
        if class_name and user_name:
            if is_valid_name(user_name):
                st.session_state.user_name = user_name
                st.session_state.class_name = class_name
                st.rerun()
            else:
                st.error("姓名必须为2到3个汉字，请重新输入。")
    st.stop()
    
# 结束页面
elif st.session_state.end:
    st.markdown("感谢你的参与，测试结束。请点击以下链接进入问卷作答环节：https://www.wjx.cn/newwjx/manage/myquestionnaires.aspx")
    st.stop()
# 练习环节指导语    
elif not st.session_state.example:
    st.info(guide(st.session_state.user_name))    
# 进入测试界面，左栏显示阅读材料，右栏为对话区域
col1, col2= st.columns([1.35,1])

with col1:
    h = 550
    # PDF 文件路径
    pdf_file_path = reading_material[st.session_state.current_question_index]

    # 将 PDF 文件转换为 Base64 格式
    with open(pdf_file_path, "rb") as f:
        base64_pdf = base64.b64encode(f.read()).decode('utf-8')

    # 嵌入 PDF 文件
    st.markdown(
        f"""
        <style>
        iframe {{
            background-color: #F1F8E9;  /* 替换为你主题的背景颜色 */
            border: none;
            width: 100%;
            height: 550px;
        }}
        </style>
        <iframe src="data:application/pdf;base64,{base64_pdf}" width="700" height="550" type="application/pdf"></iframe>
        """,
        unsafe_allow_html=True,
    )
    #question = reading_material[st.session_state.current_question_index]
    #st.markdown(question, unsafe_allow_html=True)

with col2:    
    messages_placeholder = st.empty()
    if  st.session_state.first:
        with messages_placeholder.container(height=h):
            get_response(f"你好，我是{st.session_state.user_name}", file)# 离开欢迎界面后向GPTs发送一条打招呼消息
            st.session_state.first = False

    display_chat()
    
    input_text = st.chat_input("你的回答 ", key="input_text")# 学生提交回答后获取调用函数获取回复                   
    if input_text:
        get_response(input_text, file)
   
    # 确定当前按钮的标签
    if st.session_state.current_question_index == 0:
        button_label = "开始正式测试"
    elif st.session_state.current_question_index < len(reading_material) - 1:
        button_label = "进入下一部分"
    else:
        button_label = "完成测试"
        
    if st.button(button_label):
        st.session_state.show_confirmation = True
        
    if st.session_state.show_confirmation:
        if st.session_state.current_question_index == 0:
            st.warning("确定要进入正式测试吗？当你熟悉了对话操作后请再点击确认进入正式测试。")
        elif st.session_state.current_question_index < len(reading_material) - 1:
            st.warning("确定要进入下一部分吗？点击确认后你将无法返回当前部分的作答，请确保小风告诉你进入下一部分后再点击确认。")
        else:
            st.warning("确定要完成测试吗？点击确认后你将无法返回测试，请确保小风告诉你测试结束后再点击确认。")
    
        col1, col2 = st.columns(2)
        with col1:
            if st.button("确认"):
                st.session_state.show_confirmation = False
                st.session_state.all_history.append(st.session_state.history[2:])# 点击下一题后将当前材料的对话记录保存到所有对话历史中
                st.session_state.history = []# 清空当前对话记录
                st.session_state.file_context_added = False
                if st.session_state.current_question_index == len(reading_material) - 1:
                    chat2file()# 导出对话历史文件
                    st.success("考试完成！聊天记录已保存到文件。")
                    st.rerun()
                else:
                    st.session_state.current_question_index += 1
                    st.session_state.first = True
                    st.session_state.example = True
                    st.rerun()
                
        with col2:
            if st.button("取消"):
                st.session_state.show_confirmation = False
                st.rerun()


            
    st.markdown('<div class="custom-button"></div>', unsafe_allow_html=True)
