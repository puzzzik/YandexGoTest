# Алгоритм сортировки.
Пусть `n - Размер генерируемого файла`, `m - Объём используемой оперативной памяти`.
Тогда возможно несколько вариантов:
- при `n <= m` (если оперативной памяти можно выделить столько же или больше, чем объём самого файла).
- при `n > m` (если оперативной памяти выделяется меньше, чем объём самого файла).

В первом случае будет выполнения стандартная сортировка слиянием из бибилиотеки Swift. В среднем выполняется за `O(n*logn)`.
Во втором случае исходный файл разделится на несколько отсортированных временных, размер которых примерно равен объёму выделяемой оперативной памяти. При создании каждого файла он сортируется. 
После создания всех временных файлов будет происходить их слияние.
Используется массив, элементы которого являются итераторами файлов. То есть в массиве столько значений, сколько и файлов.
В цикле пока итераторы не перестанут указывать на строки из файлов на каждой итерации будет искаться минимальный элемент из тех, на которые указывают итераторы.
И на каждой итерации минимальный элемент записывается в новый файл - результат.
Этот алгоритм имеет асимптотику `O(n*logm + n*m)`, однако если учесть, что `n*m` имеет больший порядок, чем `n*logm`, то конечная асимптотика будет равна `O(n*m)`