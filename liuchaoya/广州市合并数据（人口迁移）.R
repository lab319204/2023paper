
# 数据来源：广州市统计年鉴（2008年-2022年）表1-3各区户籍人口迁移情况
# 注：为方便进行整合，将各个表的数据粘贴至一个新表（广州市人口迁移情况）中，一个年份的数据为一个sheet
# 主要目的：通过公开数据整理成面板数据，为后续数据拼接整合做准备

# 加载必要的包
library(readxl)
library(dplyr)
library(openxlsx)  

#一、引入数据

# 设置文件路径
file_path <- "广州市人口迁移情况.xlsx"
# 读取Excel文件中的所有sheet
sheets <- excel_sheets(file_path)

# 二、处理数据
# 读取第一个sheet，并添加年份列
main_data <- read_excel(file_path, sheet = sheets[1], col_names = FALSE) %>%
  mutate(年份 = sheets[1])
#以第一个表为基表
# 读取并处理除第一个sheet以外的其他sheet
for (sheet_name in sheets[-1]) {
  data <- read_excel(file_path, sheet = sheet_name, col_names = FALSE)
  
  # 找到第一列值为“全市”的行索引
  first_row_index <- which(data[[1]] == "全市")
  
  # 如果找到了“全市”，则保留从该行开始的所有行
  if (length(first_row_index) > 0) {
    first_row_index <- first_row_index[1]  # 取第一个匹配的行
    data <- data[first_row_index:nrow(data), ]
    
    # 添加年份列
    data <- mutate(data, 年份 = sheet_name)
    
    # 拼接到主数据框
    main_data <- bind_rows(main_data, data)
  } else {
    warning(paste("在sheet", sheet_name, "中未找到'全市'"))
  }
}

# 调整列顺序，将“年份”列移动到最左侧
main_data <- select(main_data, 年份, everything())

#三、重命名各列指标名称
# 修改第三行第一列的值为 "年份"
main_data[3, 1] <- "年份"
# 将第三行设置为列名
colnames(main_data) <- main_data[3, ]
# 删除前两行
main_data <- main_data[-c(1, 2), ]
# 重置行号
rownames(main_data) <- NULL
# 删除重复指标的第一行
main_data <- main_data[-1, ]

#四、写入数据
write.xlsx(list(CombinedSheet = main_data), file = "2008-2022广州人口迁移（面板数据）.xlsx")
