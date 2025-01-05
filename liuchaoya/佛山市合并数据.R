# 加载必要的包
library(readxl)
library(dplyr)
# 数据来源：佛山市统计年鉴（2005年-2018年）表1-3各区人口基本情况
# 注：为方便进行整合，将各个表的数据粘贴至一个新表（佛山市人口变动）中，一个年份的数据为一个sheet
# 主要目的：通过公开数据整理成面板数据，为后续数据拼接整合做准备

#一、引入数据
# 设置文件路径
file_path <- "佛山人口变动情况.xlsx"
# 获取文件中的所有工作表名称
sheet_names <- excel_sheets(file_path)

#二、数据处理
# 读取第一个工作表作为基础数据框
base_data <- read_excel(file_path, sheet = sheet_names[1])
# 确保基础表格的列名唯一
names(base_data) <- make.unique(names(base_data))
# 获取最后7个工作表的名称
last_7_sheets <- tail(sheet_names, 7)
# 依次读取其余工作表的最后5列并拼接到基础表格
for (sheet in sheet_names[-1]) {
# 读取当前工作表
  sheet_data <- read_excel(file_path, sheet = sheet)
# 删除多余数据：对最后7个工作表执行删除第13行的操作
  if (sheet %in% last_7_sheets) {
# 删除第13行
    sheet_data <- sheet_data[-13, ]
  }
# 选择最后5列
  last_5_columns <- sheet_data %>% select(tail(names(sheet_data), 5))
# 确保每次提取的最后5列的列名唯一
  names(last_5_columns) <- make.unique(names(last_5_columns))
# 调整行数以匹配基础数据框的行数
  if (nrow(last_5_columns) < nrow(base_data)) {
    # 增加 NA 行到 last_5_columns 以匹配基础数据框的行数
    last_5_columns <- bind_rows(last_5_columns, tibble(matrix(NA, nrow = nrow(base_data) - nrow(last_5_columns), ncol = ncol(last_5_columns))))
    colnames(last_5_columns) <- names(last_5_columns)
  } else if (nrow(last_5_columns) > nrow(base_data)) {
# 增加 NA 行到 base_data 以匹配当前工作表的行数
    base_data <- bind_rows(base_data, tibble(matrix(NA, nrow = nrow(last_5_columns) - nrow(base_data), ncol = ncol(base_data))))
    colnames(base_data) <- names(base_data)
  }
  
#三、数据拼接
# 整理好的数据进行拼接：拼接到基础表格右边
  base_data <- bind_cols(base_data, last_5_columns, .name_repair = "unique")
}
# 删除全为 NA 的列
base_data <- base_data %>% select(where(~ any(!is.na(.))))
# 合并前两列，确定指标名称及单位
base_data <- base_data %>%
  mutate(Combined_Column = paste0(base_data[[1]], "_", base_data[[2]])) %>%
  select(-c(1,2, 3, 4, 5))  # 删除原及第3、4、5列
base_data <-  base_data %>% select(Combined_Column, everything())
# 删除多余数据：删除第1行和第9行
base_data <- base_data[-c(1, 9), ]
# 加载 zoo 包
library(zoo)
# 将第一行 NA 值填充并转换为列表形式
base_data[1, ] <- as.list(na.locf(as.vector(base_data[1, ])))
# 将整理好的数据进行转置：转置数据框
transposed_data <- as.data.frame(t(base_data), stringsAsFactors = FALSE)
# 将第一行设置为列名
colnames(transposed_data) <- transposed_data[1, ]
# 删除第一行
transposed_data <- transposed_data[-1, ]
# 重置行名，以便从1开始
rownames(transposed_data) <- NULL
# 对指标名称重命名：修改第一列的列名为“年份”，第二列为“区县”
colnames(transposed_data)[1] <- "年份"
colnames(transposed_data)[2] <- "区县"
# 去掉第一列中的“年”字
transposed_data$年份 <- gsub("年", "", transposed_data$年份)
# 删除多余数据：删除第 11、12、14、15 列
transposed_data <- transposed_data[, -c(11, 12, 14, 15)]

#四、保存数据
