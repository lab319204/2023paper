
# 数据来源：惠州市统计年鉴（2009年-2022年）表4-1 各区户籍总人口自然变动状况
# 注：为方便进行整合，将各个表的数据粘贴至一个新表（惠州市人口变动情况）中，一个年份的数据为一个sheet，由于2009-2011年数据与2012-2022年数据格式稍有差别，特在2009-2011年数据“年出生人数”行加一行“人口变动情况”作为标题行，且把“项目”替换为“指标名称”便于后续定位
# 主要目的：通过公开数据整理成面板数据，为后续数据拼接整合做准备

# 加载必要的包
library(readxl)
library(dplyr)
library(openxlsx) 

# 一、引入数据

# 设置文件路径
file_path <- "惠州市人口变动情况.xlsx"

# 读取Excel文件中的所有sheet
sheets <- excel_sheets(file_path)

# 创建一个列表用于存储处理后的数据
sheet_data_list <- list()

# 二、逐个处理每个sheet
for (sheet_name in sheets) {
  # 读取当前sheet的数据
  data <- read_excel(file_path, sheet = sheet_name, col_names = FALSE)
  
  # 找到第一列值为“指标名称”的行索引
  indicator_row_index <- which(data[[1]] == "指标名称")
  
  # 确保“指标名称”行存在
  if (length(indicator_row_index) > 0) {
    indicator_row_index <- indicator_row_index[1]  # 确保只取第一个匹配的行
    
    # 从“指标名称”开始，保留“指标名称”及以下所有行
    data <- data[indicator_row_index:nrow(data), ]
    
    # 找到“人口变动情况”这一行的索引
    change_row_index <- which(data[[1]] == "人口变动情况")
    
    # 如果找到了“人口变动情况”行，删除“指标名称”下面到“人口变动情况”之间的所有行
    if (length(change_row_index) > 0) {
      change_row_index <- change_row_index[1]  # 取第一个匹配的行
      # 删除从第二行到“人口变动情况”行及之前的所有行
      data <- data[c(1, (change_row_index+1):nrow(data)), ]    }
    
    # 将处理后的数据存储到列表中
    sheet_data_list[[sheet_name]] <- data
  } else {
    warning(paste("在sheet", sheet_name, "中未找到'指标名称'"))
  }
}
# 遍历每个工作表，直接在每个sheet中添加年份行
for (sheet_name in names(sheet_data_list)) {
  data <- sheet_data_list[[sheet_name]]
  # 创建新行，第一个值为年份，后面的值为Sheet名称
  new_row <- c(sheet_name, rep(sheet_name, ncol(data) - 1))
  # 添加新行到数据框顶部
  data <- rbind(new_row, data)
  # 更新列表中的数据
  sheet_data_list[[sheet_name]] <- data
}

#三、拼接处理表格

# 获取第一个Sheet作为基础数据框
base_data <- sheet_data_list[[1]]

# 遍历后续的Sheet进行拼接
for (i in 2:length(sheet_data_list)) {
  sheet_name <- names(sheet_data_list)[i]
  data <- sheet_data_list[[sheet_name]]
  
  # 获取第二行值并找到“惠城区”所在的列索引
  header_row <- 2
  header_values <- data[header_row, ]
  huicheng_col <- which(header_values == "惠城区")
  
  if (length(huicheng_col) > 0) {
    # 保留从“惠城区”列开始的所有列
    selected_data <- data[, huicheng_col:ncol(data)]
    colnames(selected_data) <- paste(sheet_name, colnames(selected_data), sep = "_")
    base_data <- cbind(base_data, selected_data)
  }
}
# 转置 base_data 并命名为 all_data
all_data <- t(base_data)

# 将第一行和第二行合并为新的列名
colnames(all_data) <- paste(all_data[1, ], all_data[2, ], sep = "_")

# 删除前三行
all_data <- all_data[-c(1, 2, 3), ]

# 将第一列命名为“年份”，第二列命名为“区县”
colnames(all_data)[1] <- "年份"
colnames(all_data)[2] <- "区县"
# 重排行的序号
rownames(all_data) <- seq_len(nrow(all_data))
#改为数据框形式
all_data <- as.data.frame(all_data)

#由于2013-2022数据年内出生、死亡、迁入、迁出、平均人口计量单位为万人，而2009-2012计量单位为人，因此，统一计量单位为人
# 筛选出2013到2022年的数据
all_data_subset <- all_data[all_data$年份 >= 2013 & all_data$年份 <= 2022, ]
# 确保数据是数值型，逐列转换为数值型
all_data_subset[ , 3:7] <- lapply(all_data_subset[ , 3:7], function(x) as.numeric(as.character(x)))
# 对这些行的第3到第7列乘以10000
all_data_subset[ , 3:7] <- all_data_subset[ , 3:7] * 10000
# 将修改后的数据更新回原数据框（如果需要）
all_data[all_data$年份 >= 2013 & all_data$年份 <= 2022, 3:7] <- all_data_subset[ , 3:7]
#修改指标名称
colnames(all_data) <- c("年份", "地区","出生人数_人", "死亡人数_人", "迁入人数_人","迁出人数_人","年平均人数_人","出生率_‰","死亡率_‰","自然增长率_‰")

#四、写入数据
write.xlsx(list(CombinedSheet = all_data), file = "2009-2022惠州人口变动（面板数据）.xlsx")

