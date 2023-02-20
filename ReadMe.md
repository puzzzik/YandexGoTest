# Алгоритм сортировки.
Пусть `n - Размер генерируемого файла`, `m - Объём используемой оперативной памяти`.  
Тогда возможно несколько вариантов:
- при `n <= m` (если оперативной памяти можно выделить столько же или больше, чем объём самого файла).
- при `n > m` (если оперативной памяти выделяется меньше, чем объём самого файла).
____

В первом случае будет выполнения стандартная сортировка слиянием из бибилиотеки Swift.   В среднем выполняется за `O(n * logn)`.  
____

Во втором случае исходный файл разделится на несколько отсортированных временных, размер которых примерно равен объёму выделяемой оперативной памяти.   
При создании каждого файла он сортируется. 
После создания всех временных файлов будет происходить их слияние.  
Используется массив, элементы которого являются итераторами файлов. То есть в массиве столько значений, сколько и файлов.  
В цикле пока итераторы не перестанут указывать на строки из файлов на каждой итерации будет искаться минимальный элемент из тех, на которые указывают итераторы.  
И на каждой итерации минимальный элемент записывается в новый файл - результат.  
Этот алгоритм имеет асимптотику `O(n * logm + n * n / m)`. При этом `n / m - это количество временных файлов`.  
При `n = m` Асимптотика равна `n * logn + n`, то есть просто `O(n * logn)`.  
При `n = 10m` асимптотика - `10m * logm + 100m` и если убрать константы - `O(m * logm)`.  
